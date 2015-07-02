xquery version "3.0";

(:
    getSVGs.xql
    $param 'sourceID' : xml:id of an mei:mei element 
    $param 'pageID' : xml:id of an mei:surface element within that source 
    $param 'colors' : string with hex color values to be used for coloring individual states 
    
    This xQuery prepares the SVGs for a specified page of the given source. It returns a container
    element with a) the complete SVG, which is used for interaction in the SourceViewer app, and b) 
    with reduced SVGs for each state, which reflect only the shapes that establish this state, and which
    are colored according to a general coloring scheme defined in the Javascript. 
:)

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";

declare option exist:serialize "method=xml media-type=text/plain omit-xml-declaration=yes indent=yes";

(:
    local:strip-namespace()
    This generic function is used to strip namespace references from any XML. Here, it is used to remove the
    reference to the namespace in <svg:svg>, since browsers don't understand it with namespace when embedding 
    into HTML. 
:)
declare function local:strip-namespace($e as element()) as element() {
  element {QName((), local-name($e))} {
    for $child in $e/(@*,*)
    return
      if ($child instance of element())
      then local:strip-namespace($child)
      else $child
  }
};

(:
    local:addTransparency()
    take an SVG document and run in through makeTransparent.xsl. This basically sets everything to
    an opacity of 0 (= transparent), but leaves all paths in place for interaction. 
:)
declare function local:addTransparency($fullSvg,$xslPath,$highlightColor) as element() {
    let $output := transform:transform($fullSvg,
        doc(concat($xslPath,'makeTransparent.xsl')), <parameters><param name="highlightColor" value="{$highlightColor}"/></parameters>) 
    return
        $output
};

(:
    local:getStateSVG()
    This function first uses getState.xsl on the full MEI file to get a reduced version of it, which reflects that
    particular state. Then, it identifies all SVG paths referenced from this particular state, and uses them as
    parameter for getStateSVG.xsl, which returns an SVG with only the paths used in that state and on this page left.
:)
declare function local:getStateSVG($doc,$fullSVG,$state, $xslPath, $colors, $i) as element() {
    
    (:
        get a reduced version of the full MEI file which reflects the specified genetic state
    :)
    let $stateMEI := transform:transform($doc,
        doc(concat($xslPath,'getState.xsl')), <parameters><param name="state.id" value="{$state/@xml:id}"/><param name="textOnly" value="{false()}"/></parameters>)
    
    (:
        get all references to SVG paths (and, in theory, also to measure zones) within the MEI of that state
    :)
    let $shapeIDs := $stateMEI//mei:measure//mei:*[@facs]/tokenize(@facs,' ')
    
    (:
        Transform the full SVG of that page so that it only contains the SVG shapes which are referenced by the 
        specified state. The calls to getStateSVG are numbered using $i, and each state SVG gets the color at 
        position $i in the $colors array.
    :)
    let $stateSVG := transform:transform($fullSVG,
        doc(concat($xslPath,'getStateSVG.xsl')), <parameters><param name="state.id" value="{$state/@xml:id}"/><param name="color" value="{$colors[$i]}"/><param name="shape.ids" value="{string-join($shapeIDs,' ')}"/></parameters>)
    
    return
        <state id="{$state/@xml:id}" label="{$state/@label}">
            {$stateSVG}
        </state>
};


(:START OF PROCESSING:)

let $source.id := request:get-parameter('sourceID','')
let $page.id := request:get-parameter('pageID','')
let $highlightColor := request:get-parameter('highlightColor','')
let $colorString := request:get-parameter('colors','')

(:
    split the provided $colorString by comma to get an array of hex color values ('#ff0000' means red etc.)
:)
let $colors := tokenize($colorString,',')

(:
    get the MEI document and the base path for XSLTs (which is relative to the path of this xQuery)
:)
let $doc := collection('/db/apps/SourceViewer/contents/')//mei:mei[@xml:id = $source.id]
let $xslPath := '../xslt/'

(:
    get the (first) SVG element on the specified page and remove its namespace references 
:)
let $fullSvg := local:strip-namespace($doc/id($page.id)/svg:svg[1])

(:
    prepare an SVG with all paths on the current page, to be used for interaction (highlighting of events, clicking etc.)
:)
let $backgroundSvg := local:addTransparency($fullSvg,$xslPath,$highlightColor)

(:
    get the states available in the MEI file
:)
let $states := $doc//mei:genDesc[@ordered = 'true']/mei:state[@xml:id]

(:
    for each state, generate a separate SVG with a distinct color taken from the $colors array
:)
let $svgs := for $state at $i in $states
             return
                local:getStateSVG($doc,$fullSvg,$state, $xslPath, $colors, $i)



(:
    return a custom element 'container', which holds the $backgroundSVG to be used for interaction, 
    todo: a $curtainSvg, which just gives the shape of the page and can be used to 
    and individual SVGs for each state of that source
:)
return
    <container>
        <fullSVG>
            {$backgroundSvg}
        </fullSVG>
        {$svgs}
    </container>