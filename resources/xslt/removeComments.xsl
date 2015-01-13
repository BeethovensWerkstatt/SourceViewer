<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:svg="http://www.w3.org/2000/svg"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="local"
    xmlns:mei="http://www.music-encoding.org/ns/mei" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    exclude-result-prefixes="xs math xd mei svg" version="3.0">
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
            <xd:p> This stylesheet simply strips comments </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:output method="xml" indent="yes" normalization-form="fully-normalized"/>

    <!-- start processing -->
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>

    <!-- remove comments -->
    <xsl:template match="comment()" priority="1"/>

    <!-- "egalize" white space in @facs (sometimes additional white space is contained for better legibility in Oxygen) -->
    <xsl:template match="@facs" priority="1">
        <xsl:attribute name="facs" select="normalize-space(.)"/>
    </xsl:template>

    <!-- generic copy template -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
