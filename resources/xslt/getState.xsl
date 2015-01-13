<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:mei="http://www.music-encoding.org/ns/mei" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs xd" version="2.0">
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
    <xsl:variable name="nextMeasureID">
        <xsl:choose>
            <!-- if the state under consideration is the first state in the document -->
            <xsl:when test="count($states.preceding) = 0">
                
                <!-- TODO: what if state 1 and 2 differ only by events that have been _added_ to state 2, but nothing has been deleted between 1 and 2? -->
                
                <xsl:variable name="nextStateID" select="$states.following[1]" as="xs:string"/>
                <!-- out of all deletions happening between state 1 and 2, take the last deletion in file order -->
                <xsl:variable name="lastModification" select="(//mei:subst[substring(@changeState,2) = $nextStateID]/mei:del | //mei:del[substring(@changeState,2) = $nextStateID])[last()]"/>
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
    
    <!-- start the transformation -->
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- decide how to deal with modifications to the source in order to re-establish the sought state -->
    <xsl:template match="mei:*[@changeState]">
        <xsl:choose>
            <!-- in case of an <mei:subst> that happened in an earlier state, go with the material added -->
            <xsl:when test="substring(@changeState,2) = $states.preceding and local-name() = 'subst'">
                <xsl:apply-templates select="mei:add/mei:* | mei:restore/mei:*"/>
            </xsl:when>
            <!-- in case of an <mei:add> or <mei:restore> that happened in an earlier state, go with the added / restored material -->
            <xsl:when test="substring(@changeState,2) = $states.preceding and local-name() = ('add','restore')">
                <xsl:apply-templates select="mei:*"/>
            </xsl:when>
            <!-- in case of an <mei:subst> taking place in the desired state, go with the material added  -->
            <xsl:when test="substring(@changeState,2) = $state.id and local-name() = 'subst'">
                <xsl:apply-templates select="mei:add/mei:* | mei:restore/mei:*"/>
            </xsl:when>
            <!-- in case of an <mei:add> or <mei:restore> taking place in the desired state, go with its contents -->
            <xsl:when test="substring(@changeState,2) = $state.id and local-name() = ('add','restore')">
                <xsl:apply-templates select="mei:*"/>
            </xsl:when>
            <!-- in case of an <mei:subst> that happens in a later state, preserve the material to be deleted in that substitution -->
            <xsl:when test="substring(@changeState,2) = $states.following and local-name() = 'subst'">
                <xsl:apply-templates select="mei:del/mei:*"/>
            </xsl:when>
            <!-- in case of an <mei:del> that happens  in a later state, keep the deleted material -->
            <xsl:when test="substring(@changeState,2) = $states.following and local-name() = ('del')">
                <xsl:apply-templates select="mei:*"/>
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
    <xsl:template match="mei:*[@sameas]">
        <xsl:apply-templates select="id(substring(@sameas,2))"/>
    </xsl:template>
    
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
        <xsl:choose>
            <!-- todo: why is this? -->
            <!--xsl:when test="$state.open">-->
            <xsl:when test="1 = 1">
                <xsl:choose>
                    <!-- when the current measure is the first one after the last modification of an open variant, it should not be considered -->
                    <xsl:when test="@xml:id = $nextMeasureID"/>
                    <!-- when the current measure appears somewhere after the first measure following the last modification, it should be stripped as well -->
                    <xsl:when test="preceding::mei:measure/@xml:id = $nextMeasureID"/>
                    <!-- when the current measure doesn't appear *after* the last modification, it belongs to the intended state and should be considered -->
                    <xsl:otherwise>
                        <xsl:next-match/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- in a closed variant, all measures should be considered -->
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- todo: remove this hard-coded bullshit -->
    <!-- this template inserts a (provided) clef that's missing because of the selection of measures -->
    <xsl:template match="mei:layer[parent::mei:staff[@n = 2] and ancestor::mei:measure[@xml:id = 'edirom_measure_a0aee85e-cacf-4065-922a-ca2dc849aea5']]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:if test="count(child::mei:*) gt 0">
                <clef xmlns="http://www.music-encoding.org/ns/mei" line="2" shape="G"/>
            </xsl:if>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
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