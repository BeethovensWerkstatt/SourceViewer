<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:svg="http://www.w3.org/2000/svg" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="local" xmlns:mei="http://www.music-encoding.org/ns/mei" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd mei svg" version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p>
                <xd:b>Created on:</xd:b> Nov 21, 2014</xd:p>
            <xd:p>
                <xd:ul>
                    <xd:li><xd:b>Author:</xd:b> Maja Hartwig</xd:li>
                    <xd:li><xd:b>Author:</xd:b> Johannes Kepper</xd:li>
                </xd:ul>
            </xd:p>
            <xd:p>
                This stylesheet gets an @id of an SVG path, identifies to which MEI element it belongs, and returns
                a JSON object string with an explanation of it, to be displayed in SourceViewer. 
            </xd:p>
            <xd:p>
                <xd:b>TODO:</xd:b> The functions about pitch ignore preceding accidentals etc., so this needs to become much more sophisticated
            </xd:p>
        </xd:desc>
    </xd:doc>
    
    <!-- get a string which tells in which state a shape was added or removed -->
    <xsl:function name="local:getStateDesc" as="xs:string">
        <xsl:param name="elem" as="node()" required="yes"/>
        
        <!-- get all ancestor elements describing modifications to the source -->
        <xsl:variable name="changeStateElems" select="$elem/ancestor::mei:*[local-name() = ('del','add','restore')]" as="node()*"/>
        
        <!-- get the closest addition and deletion. since newer modifications always wrap the existing material, the inner-most
            modification is the right one to identify in which state something was added or deleted -->
        <xsl:variable name="added" select="$elem/ancestor::mei:add[1]" as="node()?"/>
        <xsl:variable name="deleted" select="$elem/ancestor::mei:del[1]" as="node()?"/>
        
        <!-- generate a string when the element was added -->
        <xsl:variable name="addedString" as="xs:string">
            <xsl:choose>
                <!-- if there is an ancestor <mei:add> -->
                <xsl:when test="$added">
                    <!-- get the state, which may be provided on a parent::mei:subst instead of the mei:add itself -->
                    <xsl:variable name="addedState" select="if($added/@changeState) then($added/@changeState) else($added/parent::mei:subst/@changeState)" as="xs:string"/>
                    <xsl:variable name="addedStateLabel" select="$added/root()/id(replace($addedState,'#',''))/@label" as="xs:string"/>
                    <xsl:value-of select="concat('hinzugefügt in ', $addedStateLabel)"/>
                </xsl:when>
                
                <!-- when there is no ancestor <mei:add>, the element must have been part of the very first state already -->
                <xsl:otherwise>
                    <xsl:value-of select="'Variante a'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- generate a string when the element was deleted -->
        <xsl:variable name="deletedString" as="xs:string">
            <xsl:choose>
                <!-- if there is an ancestor <mei:del> -->
                <xsl:when test="$deleted">
                    <!-- get the state, which may be provided on a parent::mei:subst instead of the mei:del itself -->
                    <xsl:variable name="deletedState" select="if($deleted/@changeState) then($deleted/@changeState) else($deleted/parent::mei:subst/@changeState)" as="xs:string"/>
                    <xsl:variable name="deletedStateLabel" select="$deleted/root()/id(replace($deletedState,'#',''))/@label" as="xs:string"/>
                    <xsl:value-of select="concat('gestrichen in ', $deletedStateLabel)"/>
                </xsl:when>
                
                <!-- when there is no ancestor <mei:del>, the element must still be part of the final state -->
                <xsl:otherwise>
                    <xsl:value-of select="'in finaler Variante H'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- join the information about addition and deletion and return it -->
        <xsl:value-of select="string-join(($addedString,$deletedString),', ')"/>
    </xsl:function>
    
    <!-- this function generates a german pitch name -->
    <xsl:function name="local:getGermanPitch" as="xs:string">
        <!-- basic parameters of the note -->
        <xsl:param name="oct" as="xs:string"/>
        <xsl:param name="pname" as="xs:string"/>
        <xsl:param name="accid" as="xs:string?"/>
        
        <!-- get main pitch string -->
        <xsl:variable name="basePitch" as="xs:string">
            <xsl:choose>
                <!-- for octaves 3 ("kleine Oktave") and above -->
                <xsl:when test="number($oct) ge 3">
                    <xsl:choose>
                        <!-- with one "Kreuzvorzeichen" -->
                        <xsl:when test="$accid = ('s')">
                            <xsl:choose>
                                <xsl:when test="$pname = 'c'">cis</xsl:when>
                                <xsl:when test="$pname = 'd'">dis</xsl:when>
                                <xsl:when test="$pname = 'e'">eis</xsl:when>
                                <xsl:when test="$pname = 'f'">fis</xsl:when>
                                <xsl:when test="$pname = 'g'">gis</xsl:when>
                                <xsl:when test="$pname = 'a'">ais</xsl:when>
                                <xsl:when test="$pname = 'b'">his</xsl:when>
                            </xsl:choose>
                        </xsl:when>
                        <!-- with "Doppelkreuz" -->
                        <xsl:when test="$accid = ('ss','x')">
                            <xsl:choose>
                                <xsl:when test="$pname = 'c'">cisis</xsl:when>
                                <xsl:when test="$pname = 'd'">disis</xsl:when>
                                <xsl:when test="$pname = 'e'">eisis</xsl:when>
                                <xsl:when test="$pname = 'f'">fisis</xsl:when>
                                <xsl:when test="$pname = 'g'">gisis</xsl:when>
                                <xsl:when test="$pname = 'a'">aisis</xsl:when>
                                <xsl:when test="$pname = 'b'">hisis</xsl:when>
                            </xsl:choose>
                        </xsl:when>
                        <!-- with one "B-Vorzeichen" -->
                        <xsl:when test="$accid = ('f')">
                            <xsl:choose>
                                <xsl:when test="$pname = 'c'">ces</xsl:when>
                                <xsl:when test="$pname = 'd'">des</xsl:when>
                                <xsl:when test="$pname = 'e'">es</xsl:when>
                                <xsl:when test="$pname = 'f'">fes</xsl:when>
                                <xsl:when test="$pname = 'g'">ges</xsl:when>
                                <xsl:when test="$pname = 'a'">as</xsl:when>
                                <xsl:when test="$pname = 'b'">b</xsl:when>
                            </xsl:choose>
                        </xsl:when>
                        <!-- with "zwei Bs" -->
                        <xsl:when test="$accid = ('ff')">
                            <xsl:choose>
                                <xsl:when test="$pname = 'c'">ceses</xsl:when>
                                <xsl:when test="$pname = 'd'">deses</xsl:when>
                                <xsl:when test="$pname = 'e'">eses</xsl:when>
                                <xsl:when test="$pname = 'f'">feses</xsl:when>
                                <xsl:when test="$pname = 'g'">geses</xsl:when>
                                <xsl:when test="$pname = 'a'">ases</xsl:when>
                                <xsl:when test="$pname = 'b'">heses</xsl:when>
                            </xsl:choose>
                        </xsl:when>
                        <!-- without accidentals -->
                        <xsl:otherwise>
                            <xsl:choose>
                                <xsl:when test="$pname = 'c'">c</xsl:when>
                                <xsl:when test="$pname = 'd'">d</xsl:when>
                                <xsl:when test="$pname = 'e'">e</xsl:when>
                                <xsl:when test="$pname = 'f'">f</xsl:when>
                                <xsl:when test="$pname = 'g'">g</xsl:when>
                                <xsl:when test="$pname = 'a'">a</xsl:when>
                                <xsl:when test="$pname = 'b'">h</xsl:when>
                            </xsl:choose>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <!-- for octaves 2 ("Große Oktave") or below -->
                <xsl:otherwise>
                    <xsl:choose>
                        <!-- with one "Kreuzvorzeichen" -->
                        <xsl:when test="$accid = ('s')">
                            <xsl:choose>
                                <xsl:when test="$pname = 'c'">Cis</xsl:when>
                                <xsl:when test="$pname = 'd'">Dis</xsl:when>
                                <xsl:when test="$pname = 'e'">Eis</xsl:when>
                                <xsl:when test="$pname = 'f'">Fis</xsl:when>
                                <xsl:when test="$pname = 'g'">Gis</xsl:when>
                                <xsl:when test="$pname = 'a'">Ais</xsl:when>
                                <xsl:when test="$pname = 'b'">His</xsl:when>
                            </xsl:choose>
                        </xsl:when>
                        <!-- with "Doppelkreuz" -->
                        <xsl:when test="$accid = ('ss','x')">
                            <xsl:choose>
                                <xsl:when test="$pname = 'c'">Cisis</xsl:when>
                                <xsl:when test="$pname = 'd'">Disis</xsl:when>
                                <xsl:when test="$pname = 'e'">Eisis</xsl:when>
                                <xsl:when test="$pname = 'f'">Fisis</xsl:when>
                                <xsl:when test="$pname = 'g'">Gisis</xsl:when>
                                <xsl:when test="$pname = 'a'">Aisis</xsl:when>
                                <xsl:when test="$pname = 'b'">Hisis</xsl:when>
                            </xsl:choose>
                        </xsl:when>
                        <!-- with one "B-Vorzeichen" -->
                        <xsl:when test="$accid = ('f')">
                            <xsl:choose>
                                <xsl:when test="$pname = 'c'">Ces</xsl:when>
                                <xsl:when test="$pname = 'd'">Des</xsl:when>
                                <xsl:when test="$pname = 'e'">Es</xsl:when>
                                <xsl:when test="$pname = 'f'">Fes</xsl:when>
                                <xsl:when test="$pname = 'g'">Ges</xsl:when>
                                <xsl:when test="$pname = 'a'">As</xsl:when>
                                <xsl:when test="$pname = 'b'">B</xsl:when>
                            </xsl:choose>
                        </xsl:when>
                        <!-- with two "Bs" -->
                        <xsl:when test="$accid = ('ff')">
                            <xsl:choose>
                                <xsl:when test="$pname = 'c'">Ceses</xsl:when>
                                <xsl:when test="$pname = 'd'">Deses</xsl:when>
                                <xsl:when test="$pname = 'e'">Eses</xsl:when>
                                <xsl:when test="$pname = 'f'">Feses</xsl:when>
                                <xsl:when test="$pname = 'g'">Geses</xsl:when>
                                <xsl:when test="$pname = 'a'">Ases</xsl:when>
                                <xsl:when test="$pname = 'b'">Heses</xsl:when>
                            </xsl:choose>
                        </xsl:when>
                        <!-- without accidentals -->
                        <xsl:otherwise>
                            <xsl:choose>
                                <xsl:when test="$pname = 'c'">C</xsl:when>
                                <xsl:when test="$pname = 'd'">D</xsl:when>
                                <xsl:when test="$pname = 'e'">E</xsl:when>
                                <xsl:when test="$pname = 'f'">F</xsl:when>
                                <xsl:when test="$pname = 'g'">G</xsl:when>
                                <xsl:when test="$pname = 'a'">A</xsl:when>
                                <xsl:when test="$pname = 'b'">H</xsl:when>
                            </xsl:choose>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- get additional commata for lower octaves -->
        <xsl:variable name="lowOct" as="xs:string">
            <xsl:choose>
                <xsl:when test="$oct = '0'">,,</xsl:when>
                <xsl:when test="$oct = '1'">,</xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="''"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- get additional "Striche" for higher octaves -->
        <xsl:variable name="highOct" as="xs:string">
            <xsl:choose>
                <xsl:when test="$oct = '4'">’</xsl:when>
                <xsl:when test="$oct = '5'">’’</xsl:when>
                <xsl:when test="$oct = '6'">’’’</xsl:when>
                <xsl:when test="$oct = '7'">’’’’</xsl:when>
                <xsl:when test="$oct = '8'">’’’’’</xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="''"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- join basePitch with additional octave information and return everything -->
        <xsl:value-of select="concat($lowOct,$basePitch,$highOct)"/>
    </xsl:function>
    
    <!-- this function processes notes. It uses SMuFL code points for musical symbols,
        which may not show up here in a meaningful way. Refer to http://www.smufl.org/version/latest/
        for additional information.
    -->
    <xsl:function name="local:processNote" as="xs:string">
        <xsl:param name="note" required="yes" as="node()"/>
        <xsl:variable name="dotted" as="xs:string?">
            <xsl:choose>
                <xsl:when test="not($note/@dots)"/>
                <xsl:when test="$note/@dots = '1'"></xsl:when>
                <xsl:when test="$note/@dots = '2'"></xsl:when>
                <xsl:when test="$note/@dots = '3'"></xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="accid" as="xs:string">
            <xsl:choose>
                <xsl:when test="$note//@accid = 's'">#</xsl:when>
                <xsl:when test="$note//@accid = 'f'">b</xsl:when>
                <xsl:when test="$note//@accid = 'n'">
                    <xsl:value-of select="''"/>
                </xsl:when>
                <xsl:when test="$note//@accid = 'ss'">##</xsl:when>
                <xsl:when test="$note//@accid = 'ff'">bb</xsl:when>
                <xsl:when test="$note//@accid = 'x'">##</xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="''"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="dur" as="xs:string">
            <xsl:choose>
                <xsl:when test="$note/@dur = 1"></xsl:when>
                <xsl:when test="$note/@dur = 2"></xsl:when>
                <xsl:when test="$note/@dur = 4"></xsl:when>
                <xsl:when test="$note/@dur = 8"></xsl:when>
                <xsl:when test="$note/@dur = 16"></xsl:when>
                <xsl:when test="$note/@dur = 32"></xsl:when>
                <xsl:when test="$note/@dur = 64"></xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="pitch" select="concat(upper-case($note/@pname),$accid,$note/@oct, ' | ',local:getGermanPitch($note/@oct,$note/@pname,$note//@accid))" as="xs:string"/>
        <xsl:variable name="stateDesc" select="local:getStateDesc($note)" as="xs:string"/>
        <xsl:value-of select="concat('{&#34;type&#34;:&#34;note&#34;,',             '&#34;id&#34;:&#34;',$note/@xml:id,'&#34;,',             '&#34;stateDesc&#34;:&#34;',$stateDesc,'&#34;,',             '&#34;bravura&#34;:&#34;',$dur,$dotted,'&#34;,',             '&#34;desc&#34;:&#34;',$pitch,'&#34;}')"/>
    </xsl:function>
    
    <!-- this function processes chords. For pitches, it calls local:processNote -->
    <xsl:function name="local:processChord" as="xs:string">
        <xsl:param name="chord" required="yes" as="node()"/>
        <xsl:variable name="dotted" as="xs:string*">
            <xsl:choose>
                <xsl:when test="not($chord/@dots)"/>
                <xsl:when test="$chord/@dots = '1'">Punktierter</xsl:when>
                <xsl:when test="$chord/@dots = '2'">Doppelt punktierter</xsl:when>
                <xsl:when test="$chord/@dots = '3'">Dreifach punktierter</xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="dur" as="xs:string">
            <xsl:choose>
                <xsl:when test="$chord/@dur = 1">Ganze</xsl:when>
                <xsl:when test="$chord/@dur = 2">Halbe</xsl:when>
                <xsl:when test="$chord/@dur = 4">Viertel</xsl:when>
                <xsl:when test="$chord/@dur = 8">8-tel</xsl:when>
                <xsl:when test="$chord/@dur = 16">16-tel</xsl:when>
                <xsl:when test="$chord/@dur = 32">32-tel</xsl:when>
                <xsl:when test="$chord/@dur = 64">64-tel</xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="pitches" as="xs:string*">
            <xsl:for-each select="$chord/mei:note">
                <xsl:value-of select="concat(upper-case(@pname),@oct)"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="stateDesc" select="local:getStateDesc($chord)" as="xs:string"/>
        <xsl:value-of select="concat('{&#34;type&#34;:&#34;chord&#34;,',             '&#34;id&#34;:&#34;',$chord/@xml:id,'&#34;,',              '&#34;stateDesc&#34;:&#34;',$stateDesc,'&#34;,',             '&#34;bravura&#34;:&#34;&#34;,',             '&#34;desc&#34;:&#34;',$dotted,' Akkord ',$dur,' ',string-join($pitches,', '),'&#34;}')"/>
    </xsl:function>
    
    <!-- this function more or less only says it's a beam… -->
    <xsl:function name="local:processBeam" as="xs:string">
        <xsl:param name="beam" required="yes" as="node()"/>
        <xsl:variable name="stateDesc" select="local:getStateDesc($beam)" as="xs:string"/>
        <xsl:value-of select="concat('{&#34;type&#34;:&#34;beam&#34;,',             '&#34;id&#34;:&#34;',$beam/@xml:id,'&#34;,',              '&#34;stateDesc&#34;:&#34;',$stateDesc,'&#34;,',             '&#34;bravura&#34;:&#34;&#34;,',             '&#34;desc&#34;:&#34;Balken&#34;}')"/>
    </xsl:function>
    
    <!-- this function more or less only says it's a deletion… -->
    <xsl:function name="local:processDel" as="xs:string">
        <xsl:param name="del" required="yes" as="node()"/>
        <xsl:variable name="changeState" select="if($del/@changeState) then($del/@changeState) else($del/parent::mei:subst/@changeState)" as="xs:string"/>
        <xsl:variable name="stateLabel" select="$del/root()/id(replace($changeState,'#',''))/@label" as="xs:string"/>
        <xsl:value-of select="concat('{&#34;type&#34;:&#34;del&#34;,',              '&#34;id&#34;:&#34;',$del/@xml:id,'&#34;,',              '&#34;stateDesc&#34;:&#34;&#34;,',             '&#34;bravura&#34;:&#34;&#34;,',             '&#34;desc&#34;:&#34;Streichung in ',$stateLabel,'&#34;}')"/>
    </xsl:function>
    
    <!-- this function processes accidentals. It uses SMuFL code points for musical symbols,
        which may not show up here in a meaningful way. Refer to http://www.smufl.org/version/latest/
        for additional information. -->
    <xsl:function name="local:processAccid" as="xs:string">
        <xsl:param name="accid" required="yes" as="node()"/>
        <xsl:variable name="bravura" as="xs:string">
            <xsl:choose>
                <xsl:when test="$accid/@accid = 's'"></xsl:when>
                <xsl:when test="$accid/@accid = 'f'"></xsl:when>
                <xsl:when test="$accid/@accid = 'n'"></xsl:when>
                <xsl:when test="$accid/@accid = 'ss'"></xsl:when>
                <xsl:when test="$accid/@accid = 'ff'"></xsl:when>
                <xsl:when test="$accid/@accid = 'x'"></xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="stateDesc" select="local:getStateDesc($accid)" as="xs:string"/>
        <xsl:value-of select="concat('{&#34;type&#34;:&#34;accid&#34;,',             '&#34;id&#34;:&#34;',$accid/@xml:id,'&#34;,',             '&#34;stateDesc&#34;:&#34;',$stateDesc,'&#34;,',             '&#34;bravura&#34;:&#34;',$bravura,'&#34;,',             '&#34;desc&#34;:&#34;Vorzeichen&#34;}')"/>
    </xsl:function>
    
    <!-- this function processes rests. It uses SMuFL code points for musical symbols,
        which may not show up here in a meaningful way. Refer to http://www.smufl.org/version/latest/
        for additional information. -->
    <xsl:function name="local:processRest" as="xs:string">
        <xsl:param name="rest" required="yes" as="node()"/>
        <xsl:variable name="dotted" as="xs:string?">
            <xsl:choose>
                <xsl:when test="not($rest/@dots)"/>
                <xsl:when test="$rest/@dots = '1'"></xsl:when>
                <xsl:when test="$rest/@dots = '2'"></xsl:when>
                <xsl:when test="$rest/@dots = '3'"></xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="dur" as="xs:string">
            <xsl:choose>
                <xsl:when test="$rest/@dur = 1"></xsl:when>
                <xsl:when test="$rest/@dur = 2"></xsl:when>
                <xsl:when test="$rest/@dur = 4"></xsl:when>
                <xsl:when test="$rest/@dur = 8"></xsl:when>
                <xsl:when test="$rest/@dur = 16"></xsl:when>
                <xsl:when test="$rest/@dur = 32"></xsl:when>
                <xsl:when test="$rest/@dur = 64"></xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="stateDesc" select="local:getStateDesc($rest)" as="xs:string"/>
        <xsl:value-of select="concat('{&#34;type&#34;:&#34;rest&#34;,',             '&#34;id&#34;:&#34;',$rest/@xml:id,'&#34;,',             '&#34;stateDesc&#34;:&#34;',$stateDesc,'&#34;,',             '&#34;bravura&#34;:&#34;',$dur,$dotted,'&#34;,',             '&#34;desc&#34;:&#34;&#34;}')"/>
    </xsl:function>
    
    <!-- this function processes clefs. It uses SMuFL code points for musical symbols,
        which may not show up here in a meaningful way. Refer to http://www.smufl.org/version/latest/
        for additional information. -->
    <xsl:function name="local:processClef" as="xs:string">
        <xsl:param name="clef" required="yes" as="node()"/>
        <xsl:variable name="bravura" as="xs:string">
            <xsl:choose>
                <xsl:when test="$clef/@shape = 'F'"></xsl:when>
                <xsl:when test="$clef/@shape = 'C'"></xsl:when>
                <xsl:when test="$clef/@shape = 'G'"></xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="stateDesc" select="local:getStateDesc($clef)" as="xs:string"/>
        <xsl:value-of select="concat('{&#34;type&#34;:&#34;clef&#34;,',             '&#34;id&#34;:&#34;',$clef/@xml:id,'&#34;,',             '&#34;stateDesc&#34;:&#34;',$stateDesc,'&#34;,',             '&#34;bravura&#34;:&#34;',$bravura,'&#34;,',             '&#34;desc&#34;:&#34;',$clef/@shape,'-Schlüssel&#34;}')"/>
    </xsl:function>
    
    <!-- this function more or less only gets the text content of a directive… -->
    <xsl:function name="local:processDir" as="xs:string">
        <xsl:param name="dir" required="yes" as="node()"/>
        <xsl:variable name="stateDesc" select="local:getStateDesc($dir)" as="xs:string"/>
        <xsl:value-of select="concat('{&#34;type&#34;:&#34;dir&#34;,',             '&#34;id&#34;:&#34;',$dir/@xml:id,'&#34;,',             '&#34;stateDesc&#34;:&#34;',$stateDesc,'&#34;,',             '&#34;bravura&#34;:&#34;&#34;,',             '&#34;desc&#34;:&#34;Anweisung ',string-join($dir//text(),' '),'&#34;}')"/>
    </xsl:function>
    
    <!-- this function processes octave statements. It uses SMuFL code points for musical symbols,
        which may not show up here in a meaningful way. Refer to http://www.smufl.org/version/latest/
        for additional information. -->
    <xsl:function name="local:processOctave" as="xs:string">
        <xsl:param name="octave" required="yes" as="node()"/>
        <xsl:variable name="bravura" as="xs:string">
            <xsl:choose>
                <xsl:when test="$octave/@dis = '8' and $octave/@dis.place = 'above'"></xsl:when>
                <xsl:when test="$octave/@dis = '8' and $octave/@dis.place = 'below'"></xsl:when>
                <xsl:when test="$octave/@dis = '15' and $octave/@dis.place = 'above'"></xsl:when>
                <xsl:when test="$octave/@dis = '15' and $octave/@dis.place = 'below'"></xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="''"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="stateDesc" select="local:getStateDesc($octave)" as="xs:string"/>
        <xsl:value-of select="concat('{&#34;type&#34;:&#34;octave&#34;,',             '&#34;id&#34;:&#34;',$octave/@xml:id,'&#34;,',             '&#34;stateDesc&#34;:&#34;',$stateDesc,'&#34;,',             '&#34;bravura&#34;:&#34;',$bravura,'&#34;,',             '&#34;desc&#34;:&#34;Oktavierungsanweisung&#34;}')"/>
    </xsl:function>
    
    <!-- this function describes the range of a slur… -->
    <xsl:function name="local:processSlur" as="xs:string">
        <xsl:param name="slur" required="yes" as="node()"/>
        <xsl:variable name="stateDesc" select="local:getStateDesc($slur)" as="xs:string"/>
        <xsl:variable name="endLabel" as="xs:string">
            <xsl:choose>
                <xsl:when test="starts-with($slur/@tstamp2,'0m')">
                    <xsl:value-of select="concat(' bis Zählzeit ',substring-after($slur/@tstamp2,'0m+'))"/>
                </xsl:when>
                <xsl:when test="starts-with($slur/@tstamp2,'1m')">
                    <xsl:value-of select="concat(' bis Zählzeit ',substring-after($slur/@tstamp2,'1m+'),' des Folgetaktes')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat(' bis zum ',substring-before($slur/@tstamp2,'m+'),'.-nächsten Takt, Zählzeit ',substring-after($slur/@tstamp2,'m+'))"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="concat('{&#34;type&#34;:&#34;slur&#34;,',             '&#34;id&#34;:&#34;',$slur/@xml:id,'&#34;,',             '&#34;stateDesc&#34;:&#34;',$stateDesc,'&#34;,',             '&#34;desc&#34;:&#34;Bindebogen von Zählzeit ',$slur/@tstamp,$endLabel,'&#34;}')"/>
    </xsl:function>
    
    <!-- this function more or less only gets the text content of the dynam… -->
    <xsl:function name="local:processDynam" as="xs:string">
        <xsl:param name="dynam" required="yes" as="node()"/>
        <xsl:variable name="stateDesc" select="local:getStateDesc($dynam)" as="xs:string"/>
        <xsl:value-of select="concat('{&#34;type&#34;:&#34;dynam&#34;,',             '&#34;id&#34;:&#34;',$dynam/@xml:id,'&#34;,',             '&#34;stateDesc&#34;:&#34;',$stateDesc,'&#34;,',             '&#34;bravura&#34;:&#34;&#34;,',             '&#34;desc&#34;:&#34;Dynamik-Angabe ',string-join($dynam//text(),' '),'&#34;}')"/>
    </xsl:function>
    
    <!-- this function deals with various metamarks -->
    <xsl:function name="local:processMetaMark" as="xs:string">
        <xsl:param name="metaMark" required="yes" as="node()"/>
        <xsl:variable name="function">
            <xsl:choose>
                <xsl:when test="$metaMark/@function = 'navigation'">
                    <xsl:choose>
                        <xsl:when test="$metaMark/@target">Verweiszeichen</xsl:when>
                        <xsl:otherwise>Verweisziel</xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="$metaMark/@function = 'confirmation'">
                    <xsl:variable name="target" select="$metaMark/root()/id($metaMark/replace(@target,'#',''))" as="node()"/>
                    <xsl:variable name="typeString" as="xs:string">
                        <xsl:choose>
                            <xsl:when test="local-name($target) = 'del'">
                                <xsl:value-of select="' einer Streichung'"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="''"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:value-of select="concat('Bestätigung',$typeString)"/>
                </xsl:when>
                <xsl:when test="$metaMark/@function = 'clarification'">Verdeutlichung</xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="stateDesc" select="local:getStateDesc($metaMark)" as="xs:string"/>
        <xsl:variable name="target" as="xs:string">
            <xsl:choose>
                <xsl:when test="$metaMark/@function = 'navigation' and $metaMark/@target">
                    <xsl:value-of select="replace($metaMark/@target,'#','')"/>
                </xsl:when>
                <xsl:when test="$metaMark/@function = 'navigation' and not($metaMark/@target)">
                    <xsl:variable name="start" select="$metaMark/root()//mei:metaMark[replace(@target,'#','') = $metaMark/@xml:id][1]"/>
                    <xsl:value-of select="$start/@xml:id"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="''"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="concat('{&#34;type&#34;:&#34;metaMark&#34;,',             '&#34;id&#34;:&#34;',$metaMark/@xml:id,'&#34;,',             '&#34;stateDesc&#34;:&#34;',$stateDesc,'&#34;,',             '&#34;bravura&#34;:&#34;&#34;,',             '&#34;target&#34;:&#34;',$target,'&#34;,',             '&#34;desc&#34;:&#34;',$function,'&#34;}')"/>
    </xsl:function>
    
    <!-- @id of the <svg:path> element in question -->
    <xsl:param name="svg.id" required="yes"/>
    
    <!-- start processing -->
    <xsl:template match="/">
        
        <!-- gets all MEI elements that reference this particular svg path -->
        <xsl:variable name="elems" select="//mei:*[concat('#',$svg.id) = tokenize(@facs,' ')]" as="node()*"/>
        
        <!-- based on the local-name() of the MEI element, decide how to process it -->
        <xsl:variable name="strings" as="xs:string*">
            <xsl:for-each select="$elems">
                <xsl:choose>
                    <xsl:when test="local-name(.) = 'metaMark'">
                        <xsl:value-of select="local:processMetaMark(.)"/>
                    </xsl:when>
                    <xsl:when test="local-name(.) = 'del'">
                        <xsl:value-of select="local:processDel(.)"/>
                    </xsl:when>
                    <xsl:when test="local-name(.) = 'beam'">
                        <xsl:value-of select="local:processBeam(.)"/>
                    </xsl:when>
                    <xsl:when test="local-name(.) = 'note'">
                        <xsl:value-of select="local:processNote(.)"/>
                    </xsl:when>
                    <xsl:when test="local-name(.) = 'accid'">
                        <xsl:value-of select="local:processAccid(.)"/>
                    </xsl:when>
                    <xsl:when test="local-name(.) = 'dir'">
                        <xsl:value-of select="local:processDir(.)"/>
                    </xsl:when>
                    <xsl:when test="local-name(.) = 'octave'">
                        <xsl:value-of select="local:processOctave(.)"/>
                    </xsl:when>
                    <xsl:when test="local-name(.) = 'chord'">
                        <xsl:value-of select="local:processChord(.)"/>
                    </xsl:when>
                    <xsl:when test="local-name(.) = 'rest'">
                        <xsl:value-of select="local:processRest(.)"/>
                    </xsl:when>
                    <xsl:when test="local-name(.) = 'clef'">
                        <xsl:value-of select="local:processClef(.)"/>
                    </xsl:when>
                    <xsl:when test="local-name(.) = 'slur'">
                        <xsl:value-of select="local:processSlur(.)"/>
                    </xsl:when>
                    <xsl:when test="local-name(.) = 'beamSpan'">
                        <xsl:value-of select="local:processBeam(.)"/>
                    </xsl:when>
                    <xsl:when test="local-name(.) = 'dynam'">
                        <xsl:value-of select="local:processDynam(.)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="''"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        
        <!-- wrap everything in a JSON array and return it -->
        <xsl:value-of select="concat('[',string-join($strings,','),']')"/>
    </xsl:template>
</xsl:stylesheet>