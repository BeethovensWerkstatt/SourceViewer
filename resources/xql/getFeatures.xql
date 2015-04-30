xquery version "3.0";

(:
    getFeatures.xql
    $param 'sourceID'
    
    This xQuery takes the xml:id of an mei:mei element resembling a source, and returns 
    a JSON object with information about this source, the pages it contains, the measures
    on them, the genetical states identified in this source, and supplied notes, accidentals
    etc.
:)

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";

declare option exist:serialize "method=xml media-type=text/plain omit-xml-declaration=yes indent=yes";

(:
    local:getPage
    this function builds a JSON object for a given mei:surface element with various information
    returns the JSON object as string
:)
declare function local:getPage($doc,$surface) as xs:string {
    (:
        Get the mei:zone elements of the page, which should be refered by some mei:measure/@facs.  
        Then get all measures which have a reference to one of the $zones in their @facs attribute.
        Then query if at least one of those measures contains an mei:layer (which we take as argument
        that the measure holds encoded music).    
    :)
    let $zones := $surface//mei:zone
    let $measures := $doc//mei:measure[some $facs in tokenize(@facs,' ') satisfies substring($facs,2) = $zones/@xml:id]
    let $containsMusic := boolean(some $measure in $measures satisfies exists($measure//mei:layer))
    
    (: get basic parameters of the page :)
    let $id := $surface/@xml:id
    let $n := $surface/@n
    let $height := $surface/mei:graphic/@height
    let $width := $surface/mei:graphic/@width
    let $path := $surface/mei:graphic/@target
    
    (:
        iterate over the measures on that page (as identified above) and generate a JSON object for each of their
        refered zones, which holds information about positioning and the measure label. Returns a string.  
    :)
    let $measuresString := for $measure in $measures
                           return (
                                for $fac in $measure/tokenize(@facs,' ')
                                let $zone := $surface//mei:zone[concat('#',@xml:id) = $fac]
                                return
                           
                               '{' ||
                                    '"id":"' || $measure/@xml:id || '",' ||
                                    '"n":"' || $measure/@n || '",' ||
                                    '"label":"' || $measure/@label || '",' ||
                                    '"ulx":"' || $zone/@ulx || '",' ||
                                    '"uly":"' || $zone/@uly || '",' ||
                                    '"lrx":"' || $zone/@lrx || '",' ||
                                    '"lry":"' || $zone/@lry || '"' ||
                               '}'
                           )
                           
    (:
        returns a JSON object with all information found as a string
    :)                       
    return (
        '{' ||
            '"id":"' || $id || '",' ||
            '"n":"' || $n || '",' ||
            '"height":"' || $height || '",' ||
            '"width":"' || $width || '",' ||
            '"path":"' || $path || '",' ||
            '"containsMusic":' || (if($containsMusic) then('true') else('false')) || ',' ||
            '"hasSVG":' || (if($surface//svg:svg) then('true') else('false')) || ',' ||
            '"measures":[' || string-join($measuresString,',') || ']' ||
        '}'
    )
};


(:
    local:getStates
    This function builds a JSON object for a given mei:genDesc element with various information.
    At this point, states are considered to be ordered. 
    returns the JSON object as string
:)
declare function local:getStates($doc,$genDesc) as xs:string {
    
    (:
        get the label of the group of states, and the individual states
    :)
    let $groupLabel := $genDesc/@label
    let $states := $genDesc/mei:state
    
    (:
        for each genetic state, query if it is classified as open variant according to "#bwTerm_openVariant" 
        (which means it connects to following measures or "breaks"), and get it's position in chronological order.
    :)
    let $statesString := for $state in $states
                         let $open := if('#bwTerm_openVariant' = tokenize($state/@decls,' ')) then ('true') else('false')
                         let $position := count($state/preceding-sibling::mei:state) + 1
                         let $modifications := if($position gt 1) 
                                               then ($doc//mei:*[substring(@changeState,2) = $state/@xml:id]) 
                                               else($doc//mei:*[substring(@changeState,2) = $state/following-sibling::mei:state[1]/@xml:id])
                         let $pages := for $modification in $modifications
                                       return
                                           if($modification/@facs)
                                           then('"' || $doc/id(substring($modification/@facs,2))/ancestor::mei:surface/@xml:id || '"')
                                           else('"' || $doc/id(substring(($modification//@facs)[1],2))/ancestor::mei:surface/@xml:id || '"')
                         return (
                            '{' ||
                                '"id":"' || $state/@xml:id || '",' ||
                                '"open":' || $open || ',' ||
                                '"position":' || $position || ',' || 
                                '"label":"' || $state/@label || '",' ||
                                '"pages":[' || string-join(distinct-values($pages[. != '""']),',') || '],' ||
                                '"stateDesc":"' || normalize-space(string-join($state/mei:stateDesc//text(),' ')) || '",' ||
                                '"invariantDesc":"(vorläufig: ' || normalize-space(string-join($state/mei:stateDesc//text(),' ')) || ')"' ||
                            '}'
                         )
     (:
        returns a JSON object with all information found as a string
    :)   
    return (
        '{' ||
            '"stateGroup":"' || $groupLabel || '",' ||
            '"ordered":true,' ||
            '"states":[' || string-join($statesString,',') || ']' ||
        '}'
    )
};

(:START OF PROCESSING:)

(:
    Gets the xml:id of an mei:mei element, which is to be displayed with the SourceViewer app. 
    For the time being, a default value is provided (no parameter is sent from the Javascript side),
    so selecting a different source is done by changing this default value. 
:)
let $source.id := request:get-parameter('sourceID','jkljsdhjkdshkdbnjkdsjndsh')

let $doc := collection('/db/apps/SourceViewer/contents/')//mei:mei[@xml:id = $source.id]

let $title := $doc//mei:fileDesc/mei:titleStmt/mei:title[1]
let $id := $doc/@xml:id
let $path := document-uri($doc/root())
let $sourceRef := $doc//mei:source/mei:identifier[@type='SourceViewer.Path']
let $workRef := $doc//mei:work/mei:identifier[@type='SourceViewer.Path']

(:
    gets all pages from the given source and calls the getPage method to get a JSON string from it
:)
let $pages := $doc//mei:surface
let $pagesStrings := for $page in $pages
                     return
                        local:getPage($doc,$page)

(:
    gets all genetic states from the given source and calls the getStates method to get a JSON string from it
:)
let $stateGroups := $doc//mei:genDesc[@ordered = 'true']
let $statesStrings := for $stateGroup in $stateGroups
                      return
                        local:getStates($doc,$stateGroup)

(:
    gets all supplied elements from the given source and builds a JSON array with their xml:ids
:)
let $supplieds := $doc//mei:supplied//mei:*/@xml:id
let $suppliedStrings := for $supplied in $supplieds
                        return
                            concat('"',$supplied,'"')

(:
    since accidental elements don't preserve their xml:id during rendering with Verovio, the xml:id of their
    parent notes is put into a separate JSON array
:)
let $suppliedAccids := $doc//mei:accid[parent::mei:supplied]
let $suppliedAccidString := for $suppliedAccid in $suppliedAccids
                            return
                                concat('"',$suppliedAccid/ancestor::mei:note/@xml:id,'"')


(:
    a JSON object is created with all relevant information about this particular source
:)
return (
    '{' ||
        '"title":"' || $title || '",' ||
        '"id":"' || $id || '",' ||
        '"workRef":"' || $workRef || '",' ||
        '"sourceRef":"' || $sourceRef || '",' ||
        '"path":"' || $path || '",' ||
        '"pages":[' ||
            string-join($pagesStrings,',') ||
        '],' ||
        '"states":[' ||
            string-join($statesStrings,',') ||
        '],' ||
        '"suppliedIDs":[' ||
            string-join($suppliedStrings,',') ||
        '],' ||
        '"suppliedAccids":[' ||
            string-join($suppliedAccidString,',') ||
        ']' ||
    '}'
    )