xquery version "3.0";

(:
    getOverlayInfo.xql
    $param 'sourceID' : xml:id of an mei:mei element 
    $param 'pageID' : xml:id of an mei:surface element within that source 
    
    todo: description
:)

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";

declare option exist:serialize "method=xml media-type=text/plain omit-xml-declaration=yes indent=yes";

(:
    local:addTransparency()
    take an SVG document and run in through makeTransparent.xsl. This basically sets everything to
    an opacity of 0 (= transparent), but leaves all paths in place for interaction. 
:)
declare function local:getStateInfo($doc,$xslPath,$state) as xs:string {

    (:
        get a reduced version of the full MEI file which reflects the specified genetic state
    :)
    let $stateMEI := transform:transform($doc,
        doc(concat($xslPath,'getState.xsl')), <parameters><param name="state.id" value="{$state/@xml:id}"/></parameters>)
    
    
    let $output := transform:transform($fullSvg,
        doc(concat($xslPath,'makeTransparent.xsl')), <parameters><param name="highlightColor" value="{$highlightColor}"/></parameters>) 
    return
        $output
};




(:START OF PROCESSING:)

let $source.id := request:get-parameter('sourceID','')

(:
    get the MEI document and the base path for XSLTs (which is relative to the path of this xQuery)
:)
let $doc := collection('/db/apps/SourceViewer/contents/')//mei:mei[@xml:id = $source.id]
let $xslPath := '../xslt/'

(:
    get the states available in the MEI file
:)
let $states := $doc//mei:genDesc[@ordered = 'true']/mei:state[@xml:id]

let $enriched.doc := transform:transform($doc,
        doc(concat($xslPath,'addStateInfo.xsl')), <parameters/>)

let $states.plain := '{}'

let $states.layers := for $state in $states
                      let $meiIDs := $enriched.doc//mei:*[((@added = $state/@xml:id) or (@changeState and substring(@changeState,2) = $state/@xml:id)) and not(local-name() = 'measure')]/concat('"',@xml:id,'"')
                      let $svgIDs := $enriched.doc//mei:*[(@added = $state/@xml:id) or (@changeState and substring(@changeState,2) = $state/@xml:id)]/tokenize(normalize-space(replace(@facs,'#','')),' ')
                      let $svgIDs.ticked := for $svgID in $svgIDs
                                            return
                                                if($svgID != '') then('"' || $svgID || '"') else()
                      return
                        '{' ||
                            '"id":"' || $state/@xml:id || '",' ||
                            '"type":"layers",' ||
                            '"meiIDs":[' || string-join($meiIDs,',') || '],' ||
                            '"svgIDs":[' || string-join($svgIDs.ticked,',') || ']' ||
                        '}'

let $states.invariance := for $state in $states
                          let $native.elems := $enriched.doc//mei:*[((@added = $state/@xml:id) or (@changeState and substring(@changeState,2) = $state/@xml:id)) and not(@sameas) and not(local-name() = 'measure')]
                          let $copied.elems := $enriched.doc//mei:*[substring(@sameas,2) = $native.elems/@xml:id]
                          let $relevant.elems := ($native.elems,$copied.elems)
                          
                          let $meiIDs.prepared := for $elem in $relevant.elems
                                                  return
                                                      '"' || $elem/@xml:id  || '"'
                          let $svgIDs.ticked := for $elem in $relevant.elems
                                                let $svgs := for $ref in tokenize($elem/normalize-space(replace(@facs,'#','')),' ')
                                                             return
                                                                 '"' || $ref || '"'
                                                return
                                                    $svgs
                          let $svgIDs.final := $svgIDs.ticked[string-length(.) gt 2]                                                    
                                                    
                          return
                            '{' ||
                                '"id":"' || $state/@xml:id || '",' ||
                                '"type":"invariance",' ||
                                '"meiIDs":[' || string-join($meiIDs.prepared,',') || '],' ||
                                '"svgIDs":[' || string-join($svgIDs.final,',') || ']' ||
                            '}'

(:
    return a custom element 'container', which holds the $backgroundSVG to be used for interaction, and
    individual SVGs for each state of that source
:)
return
    '{' ||
        '"plain":[' || string-join($states.layers,',') || '],' ||
        '"layers":[' || string-join($states.layers,',') || '],' ||
        '"invariance":[' || string-join($states.invariance,',') || ']' ||
    '}'