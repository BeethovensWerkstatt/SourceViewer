<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:mei="http://www.music-encoding.org/ns/mei" xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs xd math mei" version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p>
                <xd:b>Created on:</xd:b> Sep 2, 2014</xd:p>
            <xd:p>
                <xd:ul>
                    <xd:li>
                        <xd:b>Author:</xd:b> Maja Hartwig</xd:li>
                    <xd:li>
                        <xd:b>Author:</xd:b> Johannes Kepper</xd:li>
                </xd:ul>
            </xd:p>
            <xd:p>
                This stylesheet transforms an MEI file so that it reflects exactly only one genetical state contained in the file,
                that is, it recreates "Textschicht C".
            </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:output method="xml" indent="yes"/>
    
    <!-- the xml:id of an <mei:state> element, for which the corresponding historical state of the encoded source shall be extracted -->
    <xsl:param name="state.id"/>
    <!-- todo: if I knew this, I'd be happy… -->
    <xsl:param name="textOnly"/>
    
    <!-- get the <mei:state> element, as well as all preceding and following states 
        (this depends on the assumption that only chronologically ordered states are considered) -->
    <xsl:variable name="state" select="id($state.id)" as="node()"/>
    <xsl:variable name="states.preceding" select="$state/preceding-sibling::mei:state/@xml:id" as="xs:string*"/>
    <xsl:variable name="states.following" select="$state/following-sibling::mei:state/@xml:id" as="xs:string*"/>
    
    <!-- identify if the current state is open (i.e. does not connect to the following measures) or closed (composition has continued in this state after writing the final measure) -->
    <xsl:variable name="state.open" select="'#bwTerm_openVariant' = tokenize($state/@decls,' ')" as="xs:boolean"/>
    
    <!-- get the xml:id of the first measure of this state -->
    <xsl:variable name="firstMeasureID" as="xs:string">
        <xsl:variable name="affected.measure.ids" select="//mei:genDesc/tokenize(replace(@plist,'#',''),' ')" as="xs:string*"/>
        <xsl:variable name="affected.measures" select="(//mei:measure[@xml:id = $affected.measure.ids])" as="node()*"/>
        <xsl:sequence select="$affected.measures[1]/@xml:id"/>
    </xsl:variable>
    
    <!-- start the transformation -->
    <xsl:template match="/">
        
        <!-- first, the file is stripped to only the snippet containing the state -->
        <xsl:variable name="stripped.file">
            <xsl:apply-templates mode="first.pass"/>
        </xsl:variable>
        
        <!-- second, @tstamps are added to all events -->
        <xsl:variable name="added.tstamps">
            <xsl:apply-templates select="$stripped.file" mode="add.tstamps"/>
        </xsl:variable>
        
        <!-- finally, controlEvents (like slurs) are attached with
            @startid and @endid (as opposed to @tstamp and @tstamp2 -->
        <xsl:apply-templates select="$added.tstamps" mode="bind.controlEvents"/>
    </xsl:template>
    
    <!-- decide how to deal with modifications to the source in order to re-establish the sought state -->
    <xsl:template match="mei:*[@changeState]" mode="first.pass">
        <xsl:choose>
            <!-- action happened in an earlier state -->
            <xsl:when test="substring(@changeState,2) = $states.preceding">
                <xsl:choose>
                    <!-- deletions require to check if they are restored -->
                    <xsl:when test="local-name() = 'del'">
                        <xsl:choose>
                            <!-- if the whole deletion is restored in a subsequent state, keep content -->
                            <xsl:when test="ancestor::mei:restore">
                                <xsl:apply-templates select="child::mei:*" mode="#current"/>
                            </xsl:when>
                            <!-- otherwise drop content-->
                            <xsl:otherwise/>
                        </xsl:choose>
                    </xsl:when>
                    <!-- additions / restoration from an earlier state are kept -->
                    <xsl:when test="local-name() = ('add','restore')">
                        <xsl:apply-templates select="child::mei:*" mode="#current"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <!-- action happens in the current state -->
            <xsl:when test="substring(@changeState,2) = $state.id">
                <xsl:choose>
                    <!-- content deleted in current state -> no restoration possible -> drop content, but keep
                        del for its @facs-->
                    <xsl:when test="local-name() = 'del'">
                        <xsl:copy>
                            <xsl:apply-templates select="@*" mode="#current"/>
                            <!-- the following rule preserves instructions like "aus" -->
                            <xsl:apply-templates select="descendant::mei:add[substring(@changeState,2) = ($state.id)]/mei:*" mode="#current"/>
                        </xsl:copy>
                    </xsl:when>
                    <!-- content added / restored in current state is kept -->
                    <xsl:when test="local-name() = ('add','restore')">
                        <xsl:apply-templates select="child::mei:*" mode="#current"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <!-- actions happening in the future -->
            <xsl:when test="substring(@changeState,2) = $states.following">
                <xsl:choose>
                    <!-- content will be deleted later, so keep it here -->
                    <xsl:when test="local-name() = 'del'">
                        <xsl:apply-templates select="child::mei:*" mode="#current"/>
                    </xsl:when>
                    <!-- content will be added later, so it's not available yet -->
                    <xsl:when test="local-name() = 'add'"/>
                    <!-- if content is restored later, check if it's deleted after this event -->
                    <xsl:when test="local-name() = 'restore'">
                        <xsl:choose>
                            <xsl:when test="child::mei:del[substring(@changeState,2) = ($states.following,$state.id)]">
                                <xsl:apply-templates select="child::mei:*" mode="#current"/>
                            </xsl:when>
                            <xsl:otherwise/>
                        </xsl:choose>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            
            
            
            <!-- otherwise should really not be triggered… -->
            <xsl:otherwise>
                Nothing happened
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- strip the supplied element and continue processing with its children -->
    <xsl:template match="mei:supplied" mode="first.pass">
        <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:template>
    
    <!-- when stumbling about something with an @sameas reference, switch to the referenced element and continue transformation there -->
    <!--<xsl:template match="mei:*[@sameas]">
        <xsl:apply-templates select="id(substring(@sameas,2))"/>
    </xsl:template>-->
    
    <!-- ignore bTrem and unclear elements and continue transformation with their respective children -->
    <xsl:template match="mei:bTrem | mei:unclear" mode="first.pass">
        <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:template>
    
    <!-- since Verovio doesn't understand ossia, select the "main" staff and pretend there is no ossia -->
    <xsl:template match="mei:ossia[parent::mei:measure]" mode="first.pass">
        <xsl:apply-templates select="mei:staff[@n]" mode="#current"/>
    </xsl:template>
    
    <!-- since Verovio doesn't understand <mei:accid> elements, take the @accid of all non-supplied <mei:accid> and attach them to the note -->
    <xsl:template match="mei:note[.//mei:accid[not(ancestor::mei:supplied)]]" mode="first.pass">
        <xsl:copy>
            <xsl:apply-templates select=".//@accid" mode="#current"/>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- throw away the header and facsimiles -->
    <xsl:template match="mei:meiHead | mei:facsimile" mode="first.pass"/>
    
    <!-- select only those measures affected by the "Störstelle" -->
    <xsl:template match="mei:measure" mode="first.pass">
        <xsl:choose>
            <!-- if the measure is referenced as affected by a "Störstelle", keep it -->
            <xsl:when test="@xml:id = //mei:genDesc/tokenize(replace(@plist,'#',''),' ')">
                <xsl:next-match/>
            </xsl:when>
            <!-- if measure isn't mentioned, don't keep -->
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>
    
    <!-- this template inserts a (provided) clef that's missing because of the selection of measures -->
    <xsl:template match="mei:layer" mode="first.pass">
        <xsl:choose>
            <!-- this addition should only happen in the first measure shown -->
            <xsl:when test="not(ancestor::mei:measure/@xml:id = $firstMeasureID)">
                <xsl:next-match/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="staff.n" select="parent::mei:staff/@n" as="xs:string"/>
                <xsl:variable name="initial.staffDef" select="//mei:scoreDef[1]//mei:staffDef[@n = $staff.n]" as="node()"/>
                <xsl:variable name="clefChanges" select="preceding::mei:*[(local-name() = 'clef' and ancestor::mei:staff[@n = $staff.n]) or (local-name() = 'staffDef' and @n = $staff.n and @clef.line and @clef.shape)]" as="node()*"/>
                <xsl:variable name="clefChange" select="if(count($clefChanges) gt 1) then($clefChanges[1]) else()" as="node()?"/>
                <xsl:copy>
                    <xsl:apply-templates select="@*" mode="#current"/>
                    <xsl:choose>
                        <!-- when there is an earlier clef element, copy it here -->
                        <xsl:when test="exists($clefChange) and local-name($clefChange) = 'clef'">
                            <xsl:copy-of select="$clefChange"/>
                        </xsl:when>
                        <!-- when there is a clef changed by using a staffDef, add a clef element here -->
                        <xsl:when test="exists($clefChange) and local-name($clefChange) = 'staffDef'">
                            <clef xmlns="http://www.music-encoding.org/ns/mei" line="{$clefChange/@clef.line}" shape="{$clefChange/@clef.shape}"/>
                        </xsl:when>
                        <xsl:otherwise/>
                    </xsl:choose>
                    <xsl:apply-templates select="node()" mode="#current"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
<!-- mode add.tstamps -->
    
    <!-- this template adds temporary attributes @meter.count and @meter.unit to the measure -->
    <xsl:template match="mei:measure" mode="add.tstamps">
        <xsl:variable name="meter.count" select="preceding::mei:scoreDef[@meter.count][1]/@meter.count cast as xs:integer" as="xs:integer"/>
        <xsl:variable name="meter.unit" select="preceding::mei:scoreDef[@meter.unit][1]/@meter.unit cast as xs:integer" as="xs:integer"/>
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current">
                <xsl:with-param name="meter.count" select="$meter.count" tunnel="yes"/>
                <xsl:with-param name="meter.unit" select="$meter.unit" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    <!-- this template creates a variable with all tstamps, which are then copied to all timed events in the layer -->
    <xsl:template match="mei:layer" mode="add.tstamps">
        <xsl:param name="meter.count" tunnel="yes"/>
        <xsl:param name="meter.unit" tunnel="yes"/>
        <xsl:variable name="events" select=".//mei:*[(@dur and not((ancestor::mei:*[@dur] or ancestor::mei:bTrem or ancestor::mei:fTrem)) and not(@grace)) or (local-name() = ('bTrem','fTrem','beatRpt','halfmRpt'))]"/>
        <xsl:variable name="durations" as="xs:double*">
            <xsl:for-each select="$events">
                <xsl:variable name="dur" as="xs:double">
                    <xsl:choose>
                        <xsl:when test="@dur">
                            <xsl:value-of select="1 div number(@dur)"/>
                        </xsl:when>
                        <xsl:when test="local-name() = 'bTrem'">
                            <xsl:value-of select="1 div (child::mei:*)[1]/number(@dur)"/>
                        </xsl:when>
                        <xsl:when test="local-name() = 'fTrem'">
                            <xsl:value-of select="1 div ((child::mei:*)[1]/number(@dur) * 2)"/>
                        </xsl:when>
                        <xsl:when test="local-name() = 'beatRpt'">
                            <xsl:value-of select="1 div $meter.unit"/>
                        </xsl:when>
                        <xsl:when test="local-name() = 'halfmRpt'">
                            <xsl:value-of select="($meter.count div 2) div $meter.unit"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="tupletFactor" as="xs:double">
                    <xsl:choose>
                        <xsl:when test="ancestor::mei:tuplet">
                            <xsl:value-of select="(ancestor::mei:tuplet)[1]/number(@numbase) div (ancestor::mei:tuplet)[1]/number(@num)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="1"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="dots" as="xs:double">
                    <xsl:choose>
                        <xsl:when test="@dots">
                            <xsl:value-of select="number(@dots)"/>
                        </xsl:when>
                        <xsl:when test="local-name() = 'bTrem' and child::mei:*/@dots">
                            <xsl:value-of select="child::mei:*[@dots]/number(@dots)"/>
                        </xsl:when>
                        <xsl:when test="local-name() = 'fTrem' and child::mei:*/@dots">
                            <xsl:value-of select="child::mei:*[@dots][1]/number(@dots)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="0"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:value-of select="(2 * $dur - ($dur div math:pow(2,$dots))) * $tupletFactor"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="tstamps">
            <xsl:for-each select="$events">
                <xsl:variable name="pos" select="position()"/>
                <event id="{@xml:id}" onset="{sum($durations[position() lt $pos])}"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current">
                <xsl:with-param name="tstamps" select="$tstamps" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    <!-- this template adds a @tstamp to each event -->
    <xsl:template match="mei:layer//mei:*[(@dur and not((ancestor::mei:*[@dur] or ancestor::mei:bTrem or ancestor::mei:fTrem)) and not(@grace)) or (local-name() = ('bTrem','fTrem','beatRpt','halfmRpt'))]" mode="add.tstamps">
        <xsl:param name="tstamps" tunnel="yes"/>
        <xsl:param name="meter.count" tunnel="yes"/>
        <xsl:param name="meter.unit" tunnel="yes"/>
        <xsl:variable name="id" select="@xml:id" as="xs:string"/>
        <xsl:variable name="onset" select="$tstamps//*[@id=$id]/@onset"/>
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:choose>
                <xsl:when test="local-name() = 'bTrem'">
                    <xsl:copy-of select="child::mei:*/@dur | child::mei:*/@dots"/>
                </xsl:when>
                <xsl:when test="local-name() = 'fTrem'">
                    <xsl:copy-of select="(child::mei:*)[1]/@dur | (child::mei:*)[1]/@dots"/>
                </xsl:when>
                <xsl:when test="local-name() = 'beatRpt'">
                    <xsl:attribute name="dur" select="$meter.unit"/>
                </xsl:when>
                <xsl:when test="local-name() = 'halfmRpt'">
                    <xsl:choose>
                        <xsl:when test="$meter.count = 4 and $meter.unit = 4">
                            <xsl:attribute name="dur" select="2"/>
                        </xsl:when>
                        <xsl:when test="$meter.count = 6 and $meter.unit = 8">
                            <xsl:attribute name="dur" select="4"/>
                            <xsl:attribute name="dots" select="1"/>
                        </xsl:when>
                        <xsl:when test="$meter.count = 2 and $meter.unit = 2">
                            <xsl:attribute name="dur" select="2"/>
                        </xsl:when>
                        <xsl:when test="$meter.count = 2 and $meter.unit = 4">
                            <xsl:attribute name="dur" select="4"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="dur"/>
                            <xsl:message>Could not identify the correct duration for halfmRpt</xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
            </xsl:choose>
            <xsl:variable name="tstamp" select="($onset * $meter.unit) + 1" as="xs:double"/>
            <xsl:attribute name="tstamp" select="$tstamp"/>
            
            <!-- check for beamSpans starting at this element -->
            <xsl:variable name="staff.n" select="ancestor::mei:staff/@n" as="xs:string"/>
            <!-- todo: improve on situations with multiple layers! -->
            <xsl:variable name="beamSpans" select="ancestor::mei:measure//mei:beamSpan[@staff = $staff.n]" as="node()*"/>
            
            <!--todo: is it robust enough?-->
            <xsl:variable name="matching.beamSpan" select="$beamSpans[@tstamp = string($tstamp) or (contains(@tstamp2,'m+') and substring-after(@tstamp2,'m+') = string($tstamp)) or @tstamp2 = string($tstamp)][1]" as="node()?"/>
            <xsl:choose>
                <xsl:when test="$matching.beamSpan/@tstamp = string($tstamp)">
                    <xsl:attribute name="beam" select="'i'"/>
                    <xsl:attribute name="beamSpan.id" select="$matching.beamSpan/@xml:id"/>
                </xsl:when>
                <xsl:when test="contains($matching.beamSpan/@tstamp2,'m+') and substring-after($matching.beamSpan/@tstamp2,'m+') = string($tstamp)">
                    <xsl:attribute name="beam" select="'t'"/>
                    <xsl:attribute name="beamSpan.id" select="$matching.beamSpan/@xml:id"/>
                </xsl:when>
                <xsl:when test="$matching.beamSpan/@tstamp2 = string($tstamp)">
                    <xsl:attribute name="beam" select="'t'"/>
                    <xsl:attribute name="beamSpan.id" select="$matching.beamSpan/@xml:id"/>
                </xsl:when>
                <xsl:when test="some $beamSpan in $beamSpans satisfies 
                    ($tstamp gt $beamSpan/number(@tstamp) and 
                        (if(contains($beamSpan/@tstamp2,'m+')) 
                        then($tstamp lt number($beamSpan/substring-after(@tstamp2,'m+')))  
                        else($tstamp lt number($beamSpan/@tstamp2))) 
                    )">
                    
                    <xsl:variable name="relevant.beamSpan" select="$beamSpans[$tstamp gt number(@tstamp) and 
                        (if(contains(@tstamp2,'m+')) then($tstamp lt number(substring-after(@tstamp2,'m+'))) else($tstamp lt number(@tstamp2)))][1]" as="node()"/>
                    <xsl:attribute name="beam" select="'m'"/>
                    <xsl:attribute name="beamSpan.id" select="$relevant.beamSpan/@xml:id"/>
                </xsl:when>
            </xsl:choose>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="mei:mRest" mode="add.tstamps">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:attribute name="tstamp" select="'1'"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="mei:mSpace" mode="add.tstamps">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:attribute name="tstamp" select="'1'"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="mei:mRpt" mode="add.tstamps">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:attribute name="tstamp" select="'1'"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- mode bind.controlEvents -->
    
    <!-- add a beam element -->
    <xsl:template match="mei:*[@beam = 'i']" mode="bind.controlEvents">
        <xsl:variable name="beam.id" select="@beamSpan.id" as="xs:string"/>
        <beam xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:attribute name="xml:id" select="$beam.id"/>
            <xsl:copy>
                <xsl:apply-templates select="node() | @*" mode="#current"/>
            </xsl:copy>
            <xsl:apply-templates select="following::mei:*[@beamSpan.id = $beam.id]" mode="#current">
                <xsl:with-param name="keep" select="true()"/>
            </xsl:apply-templates>
        </beam>
    </xsl:template>
    
    <!-- these elements are dealt by the template above -->
    <xsl:template match="mei:*[@beam = ('m','t')]" mode="bind.controlEvents">
        <xsl:param name="keep" as="xs:boolean?"/>
        <xsl:if test="$keep and $keep = true()">
            <xsl:next-match/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="@beam" mode="bind.controlEvents"/>
    <xsl:template match="@beamSpan.id" mode="bind.controlEvents"/>
    
    <!-- this template adds @startid and @endid to slurs (and ties) -->
    <xsl:template match="mei:slur | mei:tie" mode="bind.controlEvents">
        <xsl:variable name="slur" select="." as="node()"/>
        <xsl:variable name="staff.n" select="@staff" as="xs:string"/>
        <xsl:variable name="start.staff" select="ancestor::mei:measure/mei:staff[@n = $staff.n]" as="node()"/>
        <xsl:variable name="start.elem" as="node()?">
            <xsl:choose>
                <!-- exactly one layer -->
                <xsl:when test="count($start.staff/mei:layer) = 1 and not(@layer)">
                    <xsl:sequence select="($start.staff//mei:*[@tstamp = $slur/@tstamp and local-name() = ('note','chord','rest')])[1]"/>
                </xsl:when>
                <!-- layer specified, and layer available -->
                <xsl:when test="exists(@layer) and @layer = $start.staff/mei:layer/@n">
                    <xsl:sequence select="($start.staff/mei:layer[@n = $slur/@layer]/mei:*[@tstamp = $slur/@tstamp and local-name() = ('note','chord','rest')])[1]"/>
                </xsl:when>
                <!-- more than one layer available, but not clearly specified -->
                <xsl:when test="count($start.staff/mei:layer) gt 1 and not(@layer)">
                    <xsl:sequence select="($start.staff//mei:*[@tstamp = $slur/@tstamp and local-name() = ('note','chord','rest')])[1]"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="measure.dist" as="xs:integer">
            <!-- calculate how many measure the slur stretches -->
            <xsl:choose>
                <xsl:when test="contains(@tstamp2,'m+')">
                    <xsl:value-of select="number(substring-before(@tstamp2,'m+')) cast as xs:integer"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="0"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="end.staff" as="node()">
            <xsl:choose>
                <xsl:when test="$measure.dist = 0">
                    <xsl:sequence select="$start.staff"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="ancestor::mei:measure/following::mei:measure[$measure.dist]/mei:staff[@n = $staff.n]"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="end.tstamp" as="xs:string">
            <xsl:choose>
                <xsl:when test="contains($slur/@tstamp2,'m+')">
                    <xsl:value-of select="substring-after($slur/@tstamp2,'m+')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$slur/@tstamp2"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="end.elem" as="node()?">
            <xsl:choose>
                <!-- exactly one layer -->
                <xsl:when test="count($end.staff/mei:layer) = 1 and not(@layer)">
                    <xsl:sequence select="$end.staff//mei:*[@tstamp = $end.tstamp][1]"/>
                </xsl:when>
                <!-- layer specified, and layer available -->
                <xsl:when test="exists(@layer) and @layer = $end.staff/mei:layer/@n">
                    <xsl:sequence select="$end.staff/mei:layer[@n = $slur/@layer]/mei:*[@tstamp = $end.tstamp][1]"/>
                </xsl:when>
                <!-- more than one layer available, but not clearly specified -->
                <xsl:when test="count($end.staff/mei:layer) gt 1 and not(@layer)">
                    <xsl:sequence select="$end.staff//mei:*[@tstamp = $end.tstamp][1]"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:if test="not($start.elem)">
            <xsl:message select="concat('there seems to be no matching element for slur/@xml:id=',$slur/@xml:id,' at tstamp=',$slur/@tstamp,' in state ',$state.id)"/>
        </xsl:if>
        <xsl:if test="not($end.elem)">
            <xsl:message select="concat('there seems to be no matching element for slur/@xml:id=',$slur/@xml:id,' at tstamp2=',$slur/@tstamp2,' in state ',$state.id)"/>
        </xsl:if>
        <xsl:copy>
            <xsl:attribute name="startid" select="concat('#',$start.elem/@xml:id)"/>
            <xsl:attribute name="endid" select="concat('#',$end.elem/@xml:id)"/>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- required only as exist-db doesn't support the regular math:pow function: bug! -->
    <xsl:function name="math:pow">
        <xsl:param name="base"/>
        <xsl:param name="power"/>
        <xsl:choose>
            <xsl:when test="number($base) != $base or number($power) != $power">
                <xsl:value-of select="'NaN'"/>
            </xsl:when>
            <xsl:when test="$power = 0">
                <xsl:value-of select="1"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$base * math:pow($base,$power - 1)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- generic copy template -->
    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>