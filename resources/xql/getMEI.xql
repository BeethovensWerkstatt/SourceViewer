xquery version "1.0";

(:
    getMEI.xql
    $param 'sourceID' : xml:id of an mei:mei element 
    $param 'stateID' (optional) : xml:id of an mei:state within that file
    
    This xQuery is used to access an MEI file for multiple purposes. First, it can be used
    to get the full XML, which is then displayed in the XML view of the SourceViewer app. 
    Second, if an xml:id of a state in that file is provided, the file is transformed to
    only reflect this particular state, which is used for rendering this state. An additional
    xsl ('preparRendering.xsl') is used to adjust the MEI for some of Verovio's specifc requirements. 
:)

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";

declare option exist:serialize "method=xml media-type=text/plain omit-xml-declaration=yes indent=yes";

(:START OF PROCESSING:)

let $source.id := request:get-parameter('sourceID','')
let $state.id := request:get-parameter('stateID','')

(:
    get the MEI document and the base path for XSLTs (which is relative to the path of this xQuery)
:)
let $doc := collection('/db/apps/SourceViewer/contents/')//mei:*[@xml:id = $source.id]
let $xslPath := '../xslt/'

(:
    remove comments from the MEI file 
:)
let $rawDoc := transform:transform($doc,
                      doc(concat($xslPath,'removeComments.xsl')), <parameters/>)

(:
    the output depends on whether a stateID is provided. If so, the MEI is processed to reflect only that state 
    (which can be used for rendering). If no stateID is provided, the whole MEI file is returned.
:)
let $output := if($state.id = '')
                then($doc)
                else(
                    let $stripped :=      transform:transform($doc,
                      doc(concat($xslPath,'getState.xsl')), <parameters><param name="state.id" value="{$state.id}"/><param name="textOnly" value="{true()}"/></parameters>)
                  
                    let $prep := transform:transform($stripped,
                                 doc(concat($xslPath,'prepareRendering.xsl')), <parameters/>)
                    return 
                        $prep
                )

return
    $output