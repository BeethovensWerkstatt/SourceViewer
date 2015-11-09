xquery version "1.0";

(:
    getDescription.xql
    $param 'sourceID' : xml:id of an mei:mei element 
    $param 'stateID' : xml:id of an mei:state within that file
    $param 'desc' : type of description to be loaded
    
    This xQuery is used to query an MEI file for a description of a specified state 
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
let $desc.type := request:get-parameter('desc','')

(:
    get the MEI document and the base path for XSLTs (which is relative to the path of this xQuery)
:)
let $doc := collection('/db/apps/SourceViewer/contents/')//mei:*[@xml:id = $source.id]
let $xslPath := '../xslt/'

let $state := $doc/id($state.id)
let $desc.elem := 
    if($desc.type = 'layers') 
    then($state/mei:stateDesc) 
    else($doc//mei:annot[@type = 'invarianceDesc' and @plist = concat('#',$state.id)])

let $html :=
    transform:transform($desc.elem, doc(concat($xslPath,'convert2HTML.xsl')), <parameters><param name="doc.path" value="{document-uri($doc)}"/></parameters>)

return
    $html