<xsl:stylesheet xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:svg="http://www.w3.org/2000/svg"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:mei="http://www.music-encoding.org/ns/mei"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd mei svg"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p>
                <xd:b>Created on:</xd:b> Nov 11, 2014</xd:p>
            <xd:p>
                <xd:ul>
                    <xd:li><xd:b>Author:</xd:b> Maja Hartwig</xd:li>
                    <xd:li><xd:b>Author:</xd:b> Johannes Kepper</xd:li>
                </xd:ul>
            </xd:p>
            <xd:p>
                This stylesheet transforms an SVG file containing all shapes of a page to reflect only a given
                state of this page. All logic about identifying the state and the shapes its build from happens 
                in the xQuery calling this XSLT.
                <xd:ul>
                    <xd:li><xd:b>$state.id</xd:b> the $state.id parameter is prepended to all existing @id attributes in order to
                        preserve the uniqueness of IDs when multiple states are rendered on the same HTML page.</xd:li>
                    <xd:li><xd:b>$shape.ids</xd:b> this string contains a space-separated list of all path/@id that should be preserved
                        for the specified state</xd:li>
                    <xd:li><xd:b>$color</xd:b> this parameter is a CSS hex color (i.e. "#ff0000"), which is used to give all shapes of
                        a state a common look.</xd:li>
                </xd:ul>                
            </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:param name="state.id" as="xs:string"/>
    <xsl:param name="shape.ids" as="xs:string"/>
    <xsl:param name="color" as="xs:string"/>
    
    <!-- turn the shape.ids string into a more useful array -->
    <xsl:variable name="shapeList" select="tokenize(replace($shape.ids,'#',''),' ')" as="xs:string*"/>
    
    <!-- start processing -->
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- add @class="overlay" to the root svg element. -->
    <xsl:template match="svg">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="class" select="'overlay'"/>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- When the @id of any given <svg:path> is contained in the $shapeList array, keep the element. Otherwise, drop it. -->
    <xsl:template match="path">
        <xsl:if test="@id = $shapeList">
            <xsl:copy>
                <xsl:apply-templates select="node() | @*"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    
    <!-- prepend the $state.id to all @id -->
    <xsl:template match="@id">
        <xsl:attribute name="id" select="concat($state.id, '_', string(.))"/>
    </xsl:template>
    
    <!-- replace all @fill values with the provided $color -->
    <xsl:template match="@fill">
        <xsl:attribute name="fill" select="$color"/>
    </xsl:template>
    
    <xsl:template match="@opacity">
        <xsl:attribute name="opacity" select="'0.8'"/>
    </xsl:template>
    
    <!-- generic copy template -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
