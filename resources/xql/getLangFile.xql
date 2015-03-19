xquery version "3.0";

(:
    getLangFile.xql
    $param 'prefLang', defaults to german ('de')
    
:)

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";

declare option exist:serialize "method=xml media-type=text/plain omit-xml-declaration=yes indent=yes";


(:START OF PROCESSING:)

let $preferred.language := request:get-parameter('prefLang','de')

let $languageDoc := doc('/db/apps/SourceViewer/resources/i18n/i18n.xml')

let $lang := if($languageDoc//value[@xml:lang = $preferred.language])
            then($preferred.language)
            else('de')

let $pairs := for $key in $languageDoc//key[string-length(./value[@xml:lang = $lang]/text()) gt 0]
            return
                '"' || $key/@xml:id || '":"' || $key/value[@xml:lang = $lang]/text() || '"'
                
(:
    return a json object with all information
:)
return
    '{"lang":"' || $lang || '", "localization": {' || string-join($pairs,',') || '}}'