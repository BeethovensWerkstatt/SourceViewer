<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:svg="http://www.w3.org/2000/svg" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:mei="http://www.music-encoding.org/ns/mei" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd mei svg" version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p>
                <xd:b>Created on:</xd:b> Apr 25, 2015</xd:p>
            <xd:p>
                <xd:ul>
                    <xd:li><xd:b>Author:</xd:b> Maja Hartwig</xd:li>
                    <xd:li><xd:b>Author:</xd:b> Johannes Kepper</xd:li>
                </xd:ul>
            </xd:p>
            <xd:p>
                This stylesheet enriches an MEI file from the Beethoven project to explicitly give
                information about the state in which an element has been added. 
            </xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:variable name="states" select="//mei:state[parent::mei:genDesc/@ordered = 'true']" as="node()*"/>
    
    <xsl:template match="mei:meiHead"/>
    
    <!-- start processing -->
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="mei:add[@changeState]">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*">
                <xsl:with-param name="added" select="substring(@changeState,2)" tunnel="yes" as="xs:string?"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:score//mei:*[@facs]">
        <xsl:param name="added" tunnel="yes" as="xs:string?"/>
        <xsl:copy>
            <xsl:choose>
                <xsl:when test="exists($added) and not($added = '')">
                    <xsl:apply-templates select="@*"/>
                    <xsl:attribute name="added" select="$added"/>
                    <xsl:apply-templates select="node()">
                        <xsl:with-param name="added" select="$added" tunnel="yes" as="xs:string?"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="@*"/>
                    <xsl:attribute name="added" select="$states[1]/@xml:id"/>
                    <xsl:apply-templates select="node()">
                        <xsl:with-param name="added" select="$states[1]/@xml:id" tunnel="yes" as="xs:string?"/>
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    
    <!-- general copy template -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>