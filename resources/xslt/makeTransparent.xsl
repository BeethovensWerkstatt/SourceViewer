<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:svg="http://www.w3.org/2000/svg" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:mei="http://www.music-encoding.org/ns/mei" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd mei svg" version="3.0">
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
                This stylesheet operates on an SVG file containing all shapes of a page, independent 
                of the state they establish. It makes all shapes transparent. The resulting SVG is
                used for interaction in SourceViewer. 
            </xd:p>
        </xd:desc>
    </xd:doc>
    
    <!-- defines the color to be used when elements are highlighted -->
    <xsl:param name="highlightColor" as="xs:string"/>
    
    <!-- start processing -->
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    <!-- add @class="baselayer" to the root svg element. -->
    <xsl:template match="svg">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="class" select="'baselayer'"/>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- set the @opacity of all svg:path to 0 = make them fully transparent -->
    <xsl:template match="@opacity">
        <xsl:attribute name="opacity" select="'0'"/>
    </xsl:template>
    
    <!-- these elements will become visible when highlighting of shapes is required. Set the 
        color for this to a value defined above-->
    <xsl:template match="@fill">
        <xsl:attribute name="fill" select="$highlightColor"/>
    </xsl:template>
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>