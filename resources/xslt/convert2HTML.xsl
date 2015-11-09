<xsl:stylesheet xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:svg="http://www.w3.org/2000/svg" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:mei="http://www.music-encoding.org/ns/mei" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd mei svg" version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p>
                <xd:b>Created on:</xd:b> August 12, 2015</xd:p>
            <xd:p>
                <xd:ul>
                    <xd:li>
                        <xd:b>Author:</xd:b> Maja Hartwig</xd:li>
                    <xd:li>
                        <xd:b>Author:</xd:b> Johannes Kepper</xd:li>
                </xd:ul>
            </xd:p>
            <xd:p>
                This stylesheet converts snippets of an MEI file into HTML
            </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:output method="html"/>
    
    <xsl:param name="doc.path" as="xs:string"/>
    <xsl:variable name="doc" select="/"/>
    
    <!-- start processing -->
    <xsl:template match="/">
        <div>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="mei:rend">
        <span>
            <xsl:variable name="classes" as="xs:string*">
                <xsl:if test="'sub' = tokenize(@rend,' ')">
                    <xsl:value-of select="'sub'"/>
                </xsl:if>
                <xsl:if test="'sup' = tokenize(@rend,' ')">
                    <xsl:value-of select="'sup'"/>
                </xsl:if>
                <xsl:if test="'underline' = tokenize(@rend,' ')">
                    <xsl:value-of select="'u'"/>
                </xsl:if>
                <xsl:if test="'italic' = tokenize(@rend,' ')">
                    <xsl:value-of select="'i'"/>
                </xsl:if>
                <xsl:if test="'bold' = tokenize(@rend,' ')">
                    <xsl:value-of select="'b'"/>
                </xsl:if>
            </xsl:variable>
            <xsl:if test="count($classes) gt 0">
                <xsl:attribute name="class" select="string-join($classes,' ')"/>
            </xsl:if>
            <xsl:apply-templates select="node()"/>
        </span>
    </xsl:template>
    <xsl:template match="text()" priority="1">
        <xsl:copy>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="mei:ref">
        <span>
            <xsl:choose>
                <xsl:when test="not(@target) or @target = ''"/>
                <xsl:otherwise>
                    <xsl:variable name="targets" select="tokenize(replace(normalize-space(@target),'#',''),' ')" as="xs:string*"/>
                    <xsl:variable name="first.target" select="$doc//*[@xml:id = $targets or @id = $targets][1]" as="node()?"/>
                    <xsl:variable name="first.target.facs" select="if($first.target/@facs) then($first.target/@facs) else($first.target/ancestor::mei:*[@facs][1]/@facs)" as="xs:string?"/>
                    <xsl:variable name="first.target.elem" select="$doc//mei:zone[@xml:id = substring($first.target.facs,2)] | $doc//svg:path[@id = substring($first.target.facs,2)]" as="node()?"/>
                    
                    <xsl:attribute name="class" select="'ref facsLink'"/>
                    <xsl:attribute name="data-targets" select="string-join($targets,' ')"/>
                    
                    <!--<xsl:choose>
                        <xsl:when test="local-name($first.target.elem) = 'zone'">
                            <xsl:attribute name="class" select="'ref facsLink'"/>
                            
                            <xsl:variable name="pageID" select="$first.target.elem/ancestor::mei:surface/@xml:id" as="xs:string"/>
                            <xsl:variable name="allZones" select="$doc//mei:zone[@xml:id = $targets]"/>
                            
                            <xsl:variable name="ulx" select="string(min($allZones/number(@ulx)))" as="xs:string"/>
                            <xsl:variable name="uly" select="string(min($allZones/number(@uly)))" as="xs:string"/>
                            <xsl:variable name="lrx" select="string(max($allZones/number(@lrx)))" as="xs:string"/>
                            <xsl:variable name="lry" select="string(max($allZones/number(@lry)))" as="xs:string"/>
                            
                            <xsl:attribute name="onclick" select="concat('showRect(&quot;', $pageID, '&quot;,&quot;',$ulx,'&quot;,&quot;',$uly,'&quot;,&quot;',$lrx,'&quot;,&quot;',$lry,'&quot;)')"/>
                        </xsl:when>
                        <xsl:when test="$doc//svg:path[@id = $targets[1]] and $doc//mei:*[$targets[1] = tokenize(replace(@facs,'#',''),' ')]">
                            <xsl:attribute name="class" select="'ref facsLink'"/>
                            <xsl:variable name="elem" select="$doc//mei:*[$targets[1] = tokenize(replace(@facs,'#',''),' ')][1]"/>
                            <xsl:attribute name="onclick" select="concat('getEventSVG(&quot;', $elem/@xml:id, '&quot;)')"/>
                        </xsl:when>
                        <xsl:when test="local-name($first.target.elem) = 'path'">
                            <xsl:attribute name="class" select="'ref facsLink'"/>
                            <xsl:attribute name="onclick" select="concat('getEventSVG(&quot;', $first.target/@xml:id, '&quot;)')"/>
                        </xsl:when>
                    </xsl:choose>-->
                    
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="node()"/>
        </span>
    </xsl:template>
    <xsl:template match="mei:title">
        <h2>
            <xsl:apply-templates select="node()"/>
        </h2>
    </xsl:template>
    <xsl:template match="mei:p">
        <p>
            <xsl:apply-templates select="node()"/>
        </p>
    </xsl:template>
    <xsl:template match="mei:lb">
        <br/>
    </xsl:template>
    
    <!-- general copy template -->
    <xsl:template match="node() | @*">
        <xsl:apply-templates select="node() | @*"/>
    </xsl:template>
</xsl:stylesheet>