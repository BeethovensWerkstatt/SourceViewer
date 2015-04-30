<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:mei="http://www.music-encoding.org/ns/mei" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs xd" version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p>
                <xd:b>Created on:</xd:b> Sep 2, 2014</xd:p>
            <xd:p>
                <xd:ul>
                    <xd:li><xd:b>Author:</xd:b> Maja Hartwig</xd:li>
                    <xd:li><xd:b>Author:</xd:b> Johannes Kepper</xd:li>
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
    
    <!-- get the xml:id of the measure following the last measure of this state -->
    <xsl:variable name="nextMeasureID" as="xs:string">
        <xsl:choose>
            <!-- if the state under consideration is the first state in the document -->
            <xsl:when test="count($states.preceding) = 0">
                
                <xsl:variable name="nextStateID" select="$states.following[1]" as="xs:string"/>
                <!-- out of all deletions happening between state 1 and 2, take the last deletion in file order -->
                <xsl:variable name="lastModification" select="(//mei:*[substring(@changeState,2) = $nextStateID])[last()]"/>
                <!-- from this last deletion that refers to state 2, take the following measure's xml:id as value for $nextMeasureID -->
                <xsl:value-of select="$lastModification/following::mei:measure[1]/@xml:id"/>
            </xsl:when>
            <!-- if the considered state is not the first one -->
            <xsl:otherwise>
                <!-- from all references to modifications occuring at a given state, take the last one in file order -->
                <xsl:variable name="lastModification" select="(//mei:*[substring(@changeState,2) = $state.id])[last()]"/>
                <!-- from this last modification, take the follwing measure's xml:id as value for $nextMeasureID -->
                <xsl:value-of select="$lastModification/following::mei:measure[1]/@xml:id"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <!-- get the xml:id of the first measure of this state -->
    <xsl:variable name="firstMeasureID" as="xs:string">
        <xsl:choose>
            <!-- if the state under consideration is the first state in the document -->
            <xsl:when test="count($states.preceding) = 0">
                
                <xsl:variable name="nextStateID" select="$states.following[1]" as="xs:string"/>
                <!-- out of all deletions happening between state 1 and 2, take the last deletion in file order -->
                <xsl:variable name="firstModification" select="(//mei:*[substring(@changeState,2) = $nextStateID])[1]"/>
                <!-- from this last deletion that refers to state 2, take the following measure's xml:id as value for $nextMeasureID -->
                <xsl:value-of select="if($firstModification/ancestor::mei:measure) then($firstModification/ancestor::mei:measure[1]/@xml:id) else($firstModification/descendant::mei:measure[1]/@xml:id)"/>
            </xsl:when>
            <!-- if the considered state is not the first one -->
            <xsl:otherwise>
                <!-- from all references to modifications occuring at a given state, take the last one in file order -->
                <xsl:variable name="firstModification" select="(//mei:*[substring(@changeState,2) = $state.id])[1]"/>
                <!-- from this last modification, take the follwing measure's xml:id as value for $nextMeasureID -->
                <xsl:value-of select="if($firstModification/ancestor::mei:measure) then($firstModification/ancestor::mei:measure[1]/@xml:id) else($firstModification/descendant::mei:measure[1]/@xml:id)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <!-- start the transformation -->
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- decide how to deal with modifications to the source in order to re-establish the sought state -->
    <xsl:template match="mei:*[@changeState]">
        <xsl:choose>
            <!-- action happened in an earlier state -->
            <xsl:when test="substring(@changeState,2) = $states.preceding">
                <xsl:choose>
                    <!-- deletions require to check if they are restored -->
                    <xsl:when test="local-name() = 'del'">
                        <xsl:choose>
                            <!-- if the whole deletion is restored in a subsequent state, keep content -->
                            <xsl:when test="parent::mei:restore">
                                <xsl:apply-templates select="child::mei:*"/>        
                            </xsl:when>
                            <!-- otherwise drop content-->
                            <xsl:otherwise/>
                        </xsl:choose>      
                    </xsl:when>
                    <!-- additions / restoration from an earlier state are kept -->
                    <xsl:when test="local-name() = ('add','restore')">
                        <xsl:apply-templates select="child::mei:*"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <!-- action happens in the current state -->
            <xsl:when test="substring(@changeState,2) = $state.id">
                <xsl:choose>
                    <!-- content deleted in current state -> no restoration possible -> drop content -->
                    <xsl:when test="local-name() = 'del'"/>
                    <!-- content added / restored in current state is kept -->
                    <xsl:when test="local-name() = ('add','restore')">
                        <xsl:apply-templates select="child::mei:*"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <!-- actions happening in the future -->
            <xsl:when test="substring(@changeState,2) = $states.following">
                <xsl:choose>
                    <!-- content will be deleted later, so keep it here -->
                    <xsl:when test="local-name() = 'del'">
                        <xsl:apply-templates select="child::mei:*"/>  
                    </xsl:when>
                    <!-- content will be added later, so it's not available yet -->
                    <xsl:when test="local-name() = 'add'"/>
                    <!-- if content is restored later, check if it's deleted after this event -->
                    <xsl:when test="local-name() = 'restore'">
                        <xsl:choose>
                            <xsl:when test="child::mei:del and child::mei:del/substring(@changeState,2) = $states.following">
                                <xsl:apply-templates select="child::mei:*"/>
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
    <xsl:template match="mei:supplied">
        <xsl:apply-templates select="node()"/>
    </xsl:template>
    
    <!-- when stumbling about something with an @sameas reference, switch to the referenced element and continue transformation there -->
    <!--<xsl:template match="mei:*[@sameas]">
        <xsl:apply-templates select="id(substring(@sameas,2))"/>
    </xsl:template>-->
    
    <!-- ignore bTrem and unclear elements and continue transformation with their respective children -->
    <xsl:template match="mei:bTrem | mei:unclear">
        <xsl:apply-templates select="node()"/>
    </xsl:template>
    
    <!-- since Verovio doesn't understand ossia, select the "main" staff and pretend there is no ossia -->
    <xsl:template match="mei:ossia[parent::mei:measure]">
        <xsl:apply-templates select="mei:staff[@n]"/>
    </xsl:template>
    
    <!-- since Verovio doesn't understand <mei:accid> elements, take the @accid of all non-supplied <mei:accid> and attach them to the note -->
    <xsl:template match="mei:note[.//mei:accid[not(ancestor::mei:supplied)]]">
        <xsl:copy>
            <xsl:apply-templates select=".//@accid"/>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- throw away the header, facsimiles, all and measures without music -->
    <!-- todo: remove the hard-coded measures -->
    <xsl:template match="mei:meiHead | mei:facsimile | mei:measure[not(mei:staff)] | mei:measure[@xml:id = ('edirom_measure_a64da9d8-bd66-4d39-b921-40de952f9d30','edirom_measure_3c2517df-0739-4cfe-b57b-39a90c0c6391')]"/>
    
    <!-- decide how to deal with measures -->
    <xsl:template match="mei:measure">
        <!-- when the current measure is not affected by any modifications, skip it -->
        <xsl:choose>
            <!-- when the current measure is the first one after the last modification of an open variant, it should not be considered -->
            <xsl:when test="@xml:id = $nextMeasureID">
                <xsl:message select="concat(@label, ': this is too late')"/>
            </xsl:when>
            <!-- when the current measure appears somewhere after the first measure following the last modification, it should be stripped as well -->
            <xsl:when test="preceding::mei:measure/@xml:id = $nextMeasureID">
                <xsl:message select="concat(@label, ': this is too late')"/>
            </xsl:when>
            <!-- when the current measure appears somewhere before the first measure of this state, it should be stripped as well -->
            <xsl:when test="following::mei:measure/@xml:id = $firstMeasureID">
                <xsl:message select="concat(@label, ': this is too early')"/>
            </xsl:when>
            <!-- when the current measure doesn't appear *after* the last modification, it belongs to the intended state and should be considered -->
            <xsl:otherwise>
                <xsl:message select="concat(@label, ': keep')"/>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- this template inserts a (provided) clef that's missing because of the selection of measures -->
    <xsl:template match="mei:layer">
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
                    <xsl:apply-templates select="@*"/>
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
                    
                    <xsl:apply-templates select="node()"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
        
        
        
    </xsl:template>
    
    <!--
    <xsl:template match="mei:score">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
            <xsl:if test="$textOnly = 'false'">
                <xsl:apply-templates select=".//mei:del[@facs]" mode="getDels"/>
            </xsl:if>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="mei:del[@facs]" mode="getDels">
        <xsl:choose>
            <xsl:when test="@changeState and substring(@changeState,2) = $state.id">
                <xsl:copy>
                    <xsl:apply-templates select="@*"/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="parent::mei:subst/@changeState and substring(parent::mei:subst/@changeState,2) = $state.id">
                <xsl:copy>
                    <xsl:apply-templates select="@*"/>
                </xsl:copy>
            </xsl:when>
        </xsl:choose>
    </xsl:template>-->
    
    <!-- generic copy template -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>