/*
 * SourceViewer app for eXist database
 * v.0.5.1
 *  
 * License: AGPL v3 
 */
 
//indicates the visibility of the page preview (top)
var showPreview = true;
//indicates the visibility of the sidebar (independent of the current view)
var showSideBox = false;

var ongoingViewChange = false;

//global variable with the results of getFeatures()
var meiFile = {};
var activePage = {};

//todo: reconstructing
/*var reconstructing = false;
var reconstructingStateID = '';*/

//svg-overlays for textual layers on the current page 
var overlays = {};
//json object with info about coloring elements according to different perspectives
var overlayInfo = {};

//currently active layer (overlaid on facsimile)
var activeOverlay;

//variables for highlighting states in the facsimile
var currentState = '';
var currentPerspective = 'plain';

//used removing the dimming after initial loading of content
var openCalls = 0;

//definition of colors to be used throughout the application (passed into database as well)
//var colors = ['#f663ff','#ff4b00','#dc322f','#d33682','#6c71c4','#0096ff','#2aa198','#859900'];
//var colors = ['#a6b2ce','#8091b7','#566a97','#293e6e','#0a245e','#0096ff','#2aa198','#859900'];
//var colors = ['#859900','#2aa198','#268bd2','#6c71c4','#d33682','#dc322f','#cb4b16','#b58900'];

var colors = ['#859900','#d33682','#2aa198','#cb4b16','#268bd2','#6c71c4','#dc322f','#b58900'];

var paperColor = '#f8f4dc';
var suppliedColor = '#999999';
//var highlightColor = '#beddff';
var highlightColor = '#c64863';

//duration in ms for displaying overlays
var ms = 8000;

//default language;
var lang = 'de';
var langFile = {};

/*
 * Setup of components
 */
// Verovio
var vrvToolkit = new verovio.toolkit();
//facsimileViewer
var facs = L.facsimileViewer('mainBox');
facs.options.lang = 'de';
//xml Editor (ace)
var editor = ace.edit("mei_editor");
editor.setTheme("ace/theme/textmate");
editor.getSession().setMode("ace/mode/xml");
editor.setReadOnly(true);




/**APP Functions*********************/

/*
 * function loadMEI()
 * loads an MEI file and puts it into the xml editor (read only)
 */
function loadMEI() {
    new jQuery.get('resources/xql/getMEI.xql',{sourceID: meiFile.id}, function(data) {

    	    var mei = data || "";
            editor.setValue(mei);
            editor.clearSelection();
    });
};
 
/*
 * function getFeatures()
 * queries an MEI file (hard-coded in getFeatures.xql) for 
 * - title of source
 * - id of document
 * - path to file in database
 * - pages 
 *     - id
 *     - n
 *     - height
 *     - width
 *     - path //path to image in database
 *     - containsMusic //if more than MEI measure are contained, i.e., notes
 *     - hasSVG //if there are svg overlays on this page
 *     - measures
 *         - id
 *         - n
 *         - label
 *         - ulx
 *         - uly
 *         - lrx
 *         - lry
 * - states
 *     - stateGroup //label of the stateGroup
 *     - ordered //boolean
 *     - states //states ordered into that group
 *         - id
 *         - open //boolean; whether this state connects to following measures or not
 *         - position //number in sequence of states
 *         - label
 * - suppliedIDs //array of IDs of supplied events
 * - suppliedAccids //array of IDs of supplied accidentals
 */ 
function getFeatures() {
    
    new jQuery.getJSON('resources/xql/getFeatures.xql', function(data) {
    	    
    	    //puts the returning JSON both into local var file and global meiFile
    	    var file = meiFile = data || "";
    	    
    	    loadMEI();
    	    
    	    /*
    	       todo: 
    	       Add mechanism to select from which source the features should be taken. 
    	       Right now, a default value is specified in getFeatures.xql
    	    */
    	    //adds preview images to the pagePreview area
    	    $.each(file.pages, function(index,page) {
    	       
    	       //left-pads the page number for getting the right images. two-digit only
    	       var pageNum = (page.n < 10) ? '0' + page.n : page.n;
    	       //adds an additional class to indicate if the page contains musical content
    	       var banClass = (page.containsMusic) ? 'music' : 'noMusic';
    	       
    	       //generates and appends the list item to the pagePreview area
    	       var entry = '<li id="preview_' + page.id + '" class="' + banClass + '"><img src="' + page.path + meiFile.sourceRef + '_p' + pageNum + '_preview.png"/><label><span data-i18n-text="singlePage">' + langFile['singlePage'] + '</span> ' + page.n + '</label></li>';
    	       $('#pagePreview ul').append(entry);
    	       
    	       //adds listener to showPage() when list item is clicked
    	       $('#preview_' + page.id).on('click', function(){
    	            showPage(page.id);
    	       });
    	       
    	       //functionality for "sliding out" the page under the mouse cursor
    	       $('#preview_' + page.id).on('mouseenter',function() {
                   if($('#preview_' + page.id).hasClass('noMusic'))
                       $('#preview_' + page.id).css('margin-right', '90px');
                   else if($('#preview_' + page.id).hasClass('music'))
                       $('#preview_' + page.id).css('margin-right','30px');
    	       });
    	       $('#preview_' + page.id).on('mouseleave',function() {
    	           if($('#preview_' + page.id).hasClass('noMusic'))
                       $('#preview_' + page.id).css('margin-right','0');
                   else if($('#preview_' + page.id).hasClass('music'))
                       $('#preview_' + page.id).css('margin-right','0');
    	           
    	       });
    	       
    	    });
    	    // automatically open first page
    	    showPage(file.pages[0].id);
    	    
    	    //if only one page available, remove page overview
    	    if(file.pages.length = 1) {
    	        $('#pagePreview h1').click();
    	        $('#pagePreview').hide();
    	    }
    	    
    	    //get the number of outgoing ajax calls
    	    openCalls = file.states[0].states.length;
    	    
    	    //prepare the renderings in overview mode
    	    $.each(file.states[0].states, function(index, state) {
    	        
    	        //generate a shared box for the state
    	        var stateBox = '<div id="stateContainer_' + state.id + '" class="stateContainer"></div>';
    	        $('#view_overview').append(stateBox);
                
                var stateHeading = '<h1><i class="toggle fa fa-caret-down fa-fw"></i><div class="headingIcon"><i class="facsOverlay fa fa-eye fa-fw" data-i18n-title="highlightInFacsimile"></i></div>  '+ state.label +'</h1>';
                var stateBox = '<div class="contentBox"></div>';
                
                $('#stateContainer_' + state.id).append(stateHeading);
                $('#stateContainer_' + state.id).append(stateBox);
                
                //event listener to minimize the state's box
                $('#stateContainer_' + state.id + ' i.fa.toggle').on('click',function() {
    	            $(this).toggleClass('fa-caret-down').toggleClass('fa-caret-right');
    	            $('#stateContainer_' + state.id + ' .contentBox').slideToggle();
    	        });
                
                //set up plain view
                var plainBox = '<div class="perspectiveBox plain"></div>';
                $('#stateContainer_' + state.id + ' .contentBox').append(plainBox);
                var plainTarget = 'verovioPlain_' + state.id;
                $('#stateContainer_' + state.id + ' .perspectiveBox.plain').append('<div class="verovioBox" id="' + plainTarget + '"></div>');
                
                //set up layers view
                var layersBox = '<div class="perspectiveBox layers" style="display: none;"></div>';
                $('#stateContainer_' + state.id + ' .contentBox').append(layersBox);
                var layersTarget = 'verovioLayers_' + state.id;
                $('#stateContainer_' + state.id + ' .perspectiveBox.layers').append('<div class="verovioBox" id="' + layersTarget + '"></div>');
                //add state description
                var layersDesc = '<div class="descBox"><h2><i class="descToggle fa fa-caret-down fa-fw"></i> <span data-i18n-text="stateDescHeading">' + langFile.stateDescHeading + '</span></h2><div class="content">' + state.stateDesc + '</div></div>';
                $('#stateContainer_' + state.id + ' .perspectiveBox.layers').append(layersDesc);
                
                //set up invariance view
                var invarianceBox = '<div class="perspectiveBox invariance" style="display: none;"></div>';
                $('#stateContainer_' + state.id + ' .contentBox').append(invarianceBox);
                var invarianceTarget = 'verovioInvariance_' + state.id;
                $('#stateContainer_' + state.id + ' .perspectiveBox.invariance').append('<div class="verovioBox" id="' + invarianceTarget + '"></div>');
                //add state description
                var invarianceDesc = '<div class="descBox"><h2><i class="descToggle fa fa-caret-down fa-fw"></i> <span data-i18n-text="stateDescHeading">' + langFile.stateDescHeading + '</span></h2><div class="content">' + state.invariantDesc + '</div></div>';
                $('#stateContainer_' + state.id + ' .perspectiveBox.invariance').append(invarianceDesc);
                
                //add listener to show / hide comments (works across layers and invariance view)
                $('#stateContainer_' + state.id + ' .descBox i.fa.descToggle').on('click',function() {
    	            $('#stateContainer_' + state.id + ' .descBox i.fa.descToggle').toggleClass('fa-caret-down').toggleClass('fa-caret-right');
    	            $('#containerLayers_' + state.id + ' .descBox .content').slideToggle();
    	        });
                
                
    	        
    	        /*$('#containerLayers_' + state.id + ' i.fa.facsOverlay').on('click',function() {
    	            console.log('highlight ' + state.id + ' in mode layers');
    	            try {
    	               facs.activateLayer(overlays[state.id]);
    	            } catch(e) {}
    	        });*/
                
                
                var targets = [];
                targets.push('#' + plainTarget);
                targets.push('#' + layersTarget);
                targets.push('#' + invarianceTarget)
                
                getState(state, targets);
    
                //todo: reconstructing
                /*$('#revertBtn_' + state.id).on('click',function() {
                    $('.revertBtn.active .fa').addClass('fa-eye').removeClass('fa-eye-slash');
                    $('.revertBtn.active').removeClass('active');
                    $('#revertBtn_' + state.id).addClass('active');
                    $('#revertBtn_' + state.id + ' .fa').removeClass('fa-eye').addClass('fa-eye-slash');
                    
                    enterReconstructMode(state.id);
                });*/     
                    
    	    });    	    
    });
    
};

/*
 * function showPage(pageID, successFunction)
 * opens a page by the specified ID
 * if successFunction is specified, it is passed 
 * to getSVGS instead of being triggered here 
 */
function showPage(pageID, func) {
    
    //stop processing when the page is already shown or pageID is missing
    if(activePage.id === pageID || pageID === '')
        return;
    
    //get page object from global meiFile
    var page = $.grep(meiFile.pages,function(pageObj,i) {
    	           return pageObj.id == pageID;
    	        })[0];
    
    //make page available in global activePage object
    activePage = page;
    
    //set scaleFactor depending on availability of musical content on that page
    //This is Beethoven-specific. We provide only reduced-size images (2000px width)
    //of those pages for copyright reasons. 
    var scaleFactor = (page.containsMusic) ? 1 : 2000 / page.width;
    var width = page.width * scaleFactor;
    var height = page.height * scaleFactor;
    
    //remove banner when page contains warning
    if($('#pagePreview li.active').hasClass('noMusic') && page.containsMusic)
           $('#unsupportedPageWarning').fadeOut();
    
    //remove class 'active' from previous active page (if any)
    $('#pagePreview li.active').toggleClass('active');
    
    //add class 'active' to the corresponding preview image
    $('#preview_' + page.id).toggleClass('active');
    
    //display banner when active page has no music content (if not already visible):
    if($('#preview_' + page.id).hasClass('noMusic') && !$('#unsupportedPageWarning').is(':visible'))       
           $('#unsupportedPageWarning').fadeIn();
    
    //turn prevPage and nextPage buttons inactive when on first or last page
    $('#prevPage').toggleClass('inactive',meiFile.pages[0].id === page.id);
    $('#nextPage').toggleClass('inactive',meiFile.pages[meiFile.pages.length - 1].id === page.id);
    
    //show page turn only when there is more than one page
    if(meiFile.pages.length > 1) {
        //bring prevPage and nextPage buttons to front
        $('#pagination').fadeIn();    
    } else {
        $('#pagination').hide();
    }
    
    
    
    //destroy previous image from facsViewer (unloads all listeners)
    facs.unload();
    //load image to facsViewer
    facs.loadImage({
        url: page.path,
        width: width,
        height: height,
        //dpi: 600,
        /*attribution: 'L. v. Beethoven: ' + meiFile.workRef + ', <a href="http://www.beethoven-haus-bonn.de/sixcms/detail.php?id=&template=opac_bibliothek_de&_opac=hans_de.pl&_dokid=wm33" target="_blank" alt="Description of the Manuscript at the Beethoven-Haus Bonn" title="Description of the Manuscript at the Beethoven-Haus Bonn">Autograph (BH 71)</a>, p.' + page.n,*/
        attribution: 'L. v. Beethoven: ' + meiFile.workRef + ', p.' + page.n,
        overlays: []
    },page.measures,scaleFactor);
    
    
    //create box in layers control for selecting the perspective
    var viewsBox = '<div id="perspectiveSwitches"></div>';
    $('form.leaflet-control-layers-list').before(viewsBox);
    
    //create the contents for that box
    var heading = '<h1 class="controlHeading" data-i18n-text="perspectiveSwitch"></h1><form id="perspectiveForm"></form>';
    var plainView = '<label><input type="radio" class="leaflet-control-layers-selector perspectiveRadio" name="leaflet-base-layers" checked="checked" value="plain"><span data-i18n-text="tabPlainPerspective"></span></label>';
    var layersView = '<label><input type="radio" class="leaflet-control-layers-selector perspectiveRadio" name="leaflet-base-layers" checked="" value="layers"><span data-i18n-text="tabLayersPerspective"></span></label>';
    var invarianceView = '<label><input type="radio" class="leaflet-control-layers-selector perspectiveRadio" name="leaflet-base-layers" checked="" value="invariance"><span data-i18n-text="tabInvariancePerspective"></span></label>';
    var separator = '<div class="leaflet-control-layers-separator"></div>';
    
    //insert everything into the HTML
    $('#perspectiveSwitches').append(heading);
    $('#perspectiveForm').append(plainView).append(layersView).append(invarianceView);
    $('#perspectiveSwitches').append(separator);
    
    //localize elements
    $('#perspectiveForm span, #perspectiveSwitches h1').each(function(index) {
        localize($(this));
    })
    
    $('#perspectiveForm input[value = ' + currentPerspective + ']').prop('checked',true);
    
    $('#perspectiveForm').on('change',function(e) {
        var val = $('#perspectiveForm input:checked').val();
        
        switchPerspective(val);
    });
    
    //todo: curtain
    //$('form.leaflet-control-layers-list').before('<h1 style="font-weight: 500;">Faksimile überlagern</h1>');
    //$('form.leaflet-control-layers-list').before('<div class="leaflet-control-layers-separator"></div>');
    
    $('form.leaflet-control-layers-list .leaflet-control-layers-separator').css('display','block;');
    
    //load SVG overlays (if any) and pass over successFunc
    if(page.hasSVG)
        getSVGs(page.id, func);
    
    //add separator after measure number control
    $('.leaflet-control-layers-overlays > label:first-child').after(separator);
    
    //add additional listener to map's "on.overlayadd" event
    facs._map.on('overlayadd', function(e){
        
        //the layer with measure numbers will fail this check, only real overlays continue
        if(typeof e._image === 'undefined')
            return;
        
        var eventID = e._leaflet_id;
        var temp = {};
        var activeStateID;
        
        for (var key in overlays) {
        
            if(!overlays.hasOwnProperty(key))
                continue;
        
            if(overlays[key]._leaflet_id === eventID) {
                temp = overlays[key];
                activeStateID = key;
            }
                
        }
        
        if(typeof activeOverlay !== 'undefined' && activeOverlay._leaflet_id === eventID) {
            console.log('layer already active');
            return;
        }
        
        activeOverlay = temp;
        currentState = activeStateID;
        $('.stateContainer h1.active').removeClass('active');
        $('#stateContainer_' + activeStateID + ' h1').addClass('active');
        adjustOverlay();
    });
};

/*
 * getOverlayInfo(sourceID)
 * gets all information about the elements belonging to a given state
 * and how these elements should be colored for a certain perspective
 * adds this information to meiFile
 */
function getOverlayInfo(sourceID) {
    
    new jQuery.getJSON('resources/xql/getOverlayInfo.xql',{sourceID: sourceID},function(result) {
    	//console.log(result);
    	
    	overlayInfo = result;
    	
    	for(var j = 0; j< result.layers.length;j++) {
    	    var layerIDs = result.layers[j].meiIDs;
    	    $.each(layerIDs, function(index,id) {
        	    try {
        	       $('.perspectiveBox.layers svg *[id = ' + id + ']').attr('stroke',colors[j]).attr('fill',colors[j]);
        	    } catch (e){
        	        
        	    }
        	});    
    	}
    	
    	for(var j = 0; j< result.invariance.length;j++) {
    	    var invarianceIDs = result.invariance[j].meiIDs;
    	    $.each(invarianceIDs, function(index,id) {
        	    try {
        	        $('.perspectiveBox.invariance svg *[id = ' + id + ']').attr('stroke',colors[j]).attr('fill',colors[j]);
                } catch (e) {
                    
                }
        	});    
    	}
    	
    	$('#loading').fadeOut();
    	
    });
    
};

/*
 * getSVGS(pageID,successFunc)
 * loads all SVGs for a given page from the database
 * return one complete svg for interaction, and an
 * additional svg for each state for overlay 
 */
function getSVGs(pageID, successFunc) {

    var pageObj = $.grep(meiFile.pages,function(page,index) {
        return page.id === pageID; 
    })[0];
    
    //define what should happen with the svgs
    var func = function(svg) {
        //get global svg as var background    	    
        var background = $(svg).children('fullSVG').children()[0];
        //turn into object
        var newLayer = {'title':'','code':background,'background':true,'headless':true};
        //add it to facsViewer as background (doesn't trigger a layer button then)
        facs.addLayer(newLayer);  
        
        //get id of background svg
        var id = $(background).attr('id');
        
        //add listener to paths in background svg to trigger queryElement function with id of that path
        $('svg[id="' + id + '"] path').on('click',function(e){
           var shape = e.currentTarget;
           var id = shape.id;
           queryElement(id);
        });
        
        //collect state svgs in a variable
        var states = $(svg).children('state');
        
        //empty arrays for all states / states not manifested on this page resp.
        overlays = {};
        facs.unUsedStates = [];
        
        //iterate through all states
        $.each(states, function(index,state) {
            
            //get id from svg element
            var stateID = $(state).attr('id');
            //get label from svg element
            var label = $(state).attr('label');
            //create object for facsViewer
            var layerOptions = {'id':stateID,'title':label,'code':$(state).children()[0],'background':false,'headless':false,'colorSample':colors[index]};
            
            //get state object from global meiFile, based on equal labels
            var stateObj = $.grep(meiFile.states[0].states,function(stateObj,i) {
               return stateObj.label == label;
            });
            
            //checks if current svg has any paths in it -> if the state is manifested on the page 
            var containsPaths = $($(state).children()[0]).children('path').length > 0;
            //if no paths are contained, add the index of this state to unUsedStates
            if(!containsPaths)
               facs.unUsedStates.push(index);
            
            //add svg to facsViewer, preserve the layer in var tmp
            var tmp = facs.addLayer(layerOptions);
            
            //iterate through the indizes of all unUsedStates and disable them
            $.each(facs.unUsedStates, function(index,indexOfState){
                //offset the index by +1 because of global "show measures" layer control
                var elem = $('.leaflet-control-layers-overlays label')[indexOfState + 1];
                   
                $(elem).children('input').attr('disabled','disabled');
                $(elem).css('color','#999999');
                $(elem).find('.colorSample').css('opacity','0.25');
            });
            
            
            
            overlays[state.id] = tmp;
            
        });
        
        //if successFunc is a function, execute it
        if(typeof successFunc === 'function')
            successFunc();  
    };
    
    //if page has been loaded before, use cached data
    if(typeof pageObj.svg !== 'undefined') {
        func(pageObj.svg);
    } else {
        //the global colors are passed in as string to get corresponding colors in the svg overlays 
        new jQuery.get('resources/xql/getSVGs.xql', {sourceID: meiFile.id, pageID:pageID, highlightColor: highlightColor, colors: colors.toString()}, function(svg) {
        	    
            //setup of returning svg:
            /*
                <container>
                    <fullSVG>
                        {$backgroundSvg}
                    </fullSVG>
                    {$svgs}
                </container>
             */
            var svg = svg || "";
            pageObj.svg = svg;
            func(svg);
        });    
    }
    
};
/*
 * function getState(state, targets) 
 * gets reduced MEI file reflecting only one state, based on 
 * the state object. passes targets parameter to 
 * renderMEI function 
 */
function getState(state, targets) {
                    
    new jQuery.ajax('resources/xql/getMEI.xql',{
        method: 'get',
        data: {sourceID: meiFile.id, stateID: state.id},
        success: function(result) {
    	    
    	    var response = result || "";
            mei = response;
            renderMEI(mei, targets);
            
            //reduce the number of outgoing ajax calls
            openCalls--;
            
            //when all ajax calls have been send out, raise the curtain 
            if(openCalls === 0) {
                getOverlayInfo(meiFile.id);
            }
    	    
    	}
    });
};

/*
 * queryElement(id)
 * queries MEI file to identify the corresponding MEI element for a 
 * given svg path id.
 * returns JSON array:
 * - type       //local-name() of MEI element
 * - id         //xml:id of MEI element
 * - stateDesc  //string describing when element has been added / removed from source
 * - bravura    //string to be rendered with bravura, i.e. note / rest symbols etc.
 * - desc       //label for description banner, used as title
 * - target?    //optional parameter, link to other elements
 * 
 * todo: only the first result in the array is processed so far
 */
function queryElement(id) {
                    
    new jQuery.getJSON('resources/xql/queryElement.xql',{sourceID: meiFile.id, pathID: id, lang: lang},function(result) {
    	
    	var data = result[0];
    	
    	//if nothing found, stop processing
    	if(typeof data === 'undefined')
    	   return;
    	
    	getEventSVG(data.id);
        
        //preserve data.id in attribute data-elemID of dialog
        $('#clickedItemDialog').attr('data-elemID',data.id);
        
        //if bravura string is specified, add it to the dialog
        if(data.bravura !== '') {
           $('#clickedItemDialog h1').html('<span style="font-family: Bravura" class="bravura ' + data.type + '">' + data.bravura + '</span> ' + data.desc);
        } else {
           $('#clickedItemDialog h1').html(data.desc);    
        }
        
        //if target is specified, add corresponding link, triggers getEventSVG
        //todo: differentiate between outgoing and incoming links
        var link = (typeof data.target !== 'undefined' && data.target !== '') ? '<a href="#" class="previewLink" onclick="getEventSVG(&#34;' + data.target + '&#34;);"><span data-i18n-text="followLink">' + langFile['followLink'] + '</span></a>' : '';
        
        //add description
        $('#clickedItemDialog .elementInfo').html(link + data.stateDesc);
        
        //add link to corresponding elements in verovio transcriptions for notes and rests, triggers showTranscription
        if(data.type === 'note' || data.type === 'rest') 
           $('#showTranscription').css('display','block').attr('onclick','showTranscription("' + data.id + '");');
        else
           $('#showTranscription').css('display','none');
        
        //add link to MEI code, triggers showCode
        $('#showCode').attr('onclick','showCode("' + data.id + '");');
        
        //fades in info dialog, and automatically fades it out after given ms (globally specified)
        if($('#clickedItemDialog:hidden')) {
           $('#clickedItemDialog').fadeIn(100,function() {
               window.setTimeout(function() {
                   if($('#clickedItemDialog').attr('data-elemID') === data.id)
                       $('#clickedItemDialog').fadeOut();
               },ms);               
           });           
        } else {
           window.setTimeout(function() {
               if($('#clickedItemDialog').attr('data-elemID') === data.id)
                   $('#clickedItemDialog').fadeOut();
           },ms);
           
        }
       
    	    
    });
};

/*
 * showTranscription(id)
 * identifies elements rendered with Verovio by their MEI xml:id
 * temporarily highlights them in verovio
 * 
 * todo: needs functionality to scroll to corresponding element in sidebar
 */
function showTranscription(elemID) {
    
    //ensures that transcriptions are visible
    if(!showSideBox || $($('#viewTabs li.active')[0]).attr('data-target') !== '#view_overview') {
        showView('#view_overview');
    }
    
    //gets all corresponding elements (could be more than one, if member of multiple states)
    var elems = $('*[id = '+elemID + ']');
    
    //change color
    $(elems).css('fill',highlightColor).css('stroke',highlightColor);
    setTimeout(function(){
        $(elems).css('fill','#000000').css('stroke','#000000');
    }, ms);
};

/*
 *  function showCode(dataID)
 *  shows the xml editor view and highlights the given string
 *  first occurence is centered, others can be accessed by ace functionality
 */
function showCode(dataID) {
    
    if(!showSideBox || $($('#viewTabs li.active')[0]).attr('data-target') !== '#view_mei') {
        showView('#view_mei');
    }
    
    editor.find(dataID,{},true);
};

/*
 * function getEventSVG(eventID)
 * takes an MEI xml:id as argument
 * queries the MEI file for corresponding SVG paths  
 * highlights them on the current page and lets the 
 * facsViewer focus on the bounding box
 */
function getEventSVG(eventID) {
    
    /*
     * returns JSON:
     * - eventID    //@xml:id of MEI event
     * - eventType  //local-name() of event
     * - facsIDs[]  //array with ids of corresponding svg shapes
     * - pageID     //@xml:id of corresponding surface
     * - pageN      //@n of corresponding surface
     */
    new jQuery.getJSON('resources/xql/getEventSVG.xql',{sourceID: meiFile.id, eventID: eventID},function(data) {
        
        //function to determine the bounding box and let facsViewer focus on that 
        var func = function() {            
            //get background-svg
            var svg = $(data.facsIDs[0]).parent();
            var width = parseFloat(svg.attr('width'));
            var height = parseFloat(svg.attr('height'));
            
            //set maximum values as starting point
            var ulx = width;
            var uly = height;
            var lrx = 0;
            var lry = 0;
            
            //iterate over all svg shapes
            $.each(data.facsIDs, function(index, id) {
            
                //get bounding box of current shape
                var bbox = svg.children(id)[0].getBBox();
                
                //modify values according to bounding boxes
                ulx = Math.min(ulx,bbox.x);
                uly = Math.min(uly,bbox.y);
                lrx = Math.max(lrx,bbox.x + bbox.width);
                lry = Math.max(lry,bbox.y + bbox.height);
                
                //make shape in background-svg visible
                $(id).attr('opacity','0.6');
                //turn off after globally defined milliseconds again. 
                setTimeout(function(){
                   $(id).attr('opacity','0');
                }, ms);
            });
            
            //Beethoven-specific: used for considering smaller-scale images  
            var ratio = activePage.width / width;
            ulx = ulx * ratio
            uly = uly * ratio;
            lrx = lrx * ratio;
            lry = lry * ratio;
            
            //let facsViewer focus on the bounding box of all svg shapes of the MEI event
            facs.showRect(ulx,uly,lrx,lry);
        };    
        
        //if event is on current page, execute func directly
        if(data.pageID === activePage.id)
            func();
        //else load event's page first and pass in func as successFunc    
        else 
            showPage(data.pageID,func);         
    });
    
};

/*
 * is this function needed? 
 */
/*function showRect(pageID,ulx,uly,lrx,lry) {
         
    if(pageID === activePage.id) {
        var scaleFactor = (activePage.containsMusic) ? 1 : 2000 / activePage.width;
        var ulx = ulx * scaleFactor, uly = uly * scaleFactor, lrx = lrx * scaleFactor, lry = lry * scaleFactor;
        
        facs.showRect(ulx,uly,lrx,lry);
        
    } else {
        
        var page = $.grep(meiFile.pages, function(pag,i){
            return pag.id === pageID;
        })[0];
        
        var scaleFactor = (page.containsMusic) ? 1 : 2000 / page.width;
        var ulx = ulx * scaleFactor, uly = uly * scaleFactor, lrx = lrx * scaleFactor, lry = lry * scaleFactor;
        
        var func = function() {
            
            facs.showRect(ulx,uly,lrx,lry);
        };
            
        showPage(pageID,func);
    }
        
};*/

/*
 * function renderMEI(mei, target)
 * takes an MEI file and an html:id (with prepending #!)
 * uses verovio to render the MEI into an svg and
 * places that svg in the HTML element with the target ID
 */
function renderMEI(mei, targets) {
    
    //options for Verovio
    var options = JSON.stringify({
      	inputFormat: 'mei',
      	border: 0,
      	scale: 35,           //scale is in percent (1 - 100)
      	ignoreLayout: 0,
      	noLayout: 1          //results in a continuous system without page breaks
    });
    
    vrvToolkit.setOptions( options );
	
	//feels like a bug in Verovio: you need to add a line break after the MEI file…
	vrvToolkit.loadData(mei + '\n');
    
    //lets Verovio render the first page. since we have a continous system, this is everything
    var svg = vrvToolkit.renderPage(1);
    
    
    $.each(targets,function(index,target) {
        //appends the resulting svg to the HTML target element
        $(target).html(svg);
    
        //iterates over all suppliedIDs (available from global meiFile)
        $.each(meiFile.suppliedIDs,function(i,suppliedID) {
            //every found suppliedID in the Verovio SVG gets painted
            $('*[id=' +suppliedID+']').css('fill',suppliedColor).css('stroke',suppliedColor);
        });
        
        //iterates over all suppliedAccids (available from global meiFile)
        $.each(meiFile.suppliedAccids,function(i,suppliedAccid) {
            //every found supplied accidental in the Verovio SVG gets painted
            $('*[id=' +suppliedAccid+'] .accid').css('fill',suppliedColor).css('stroke',suppliedColor);
        });
        
        //attach onclick listener to notes and rests to trigger getEventSVG
        //todo: should we add clefs and other elements? attention: clefs may be supplied, so no ID in the svg available. Would it break nicely?
        $(target + ' svg .note, '+ target + ' svg .rest').on('click', function(e) {
            var elem = e.currentTarget;
            //$('#status').html(elem.id);
            getEventSVG(elem.id);
        });
    });
    
};

/*
 * function adjustOverlay()
 * depending on currentState (the xml:id of the state) and currentPerspective,
 * this function colors svg overlays. 
 */
function adjustOverlay() {
    
    try {
        if(currentPerspective === 'plain') {
            $('.leaflet-overlay-pane svg.overlay path').attr('fill',highlightColor);
            
        } else if(currentPerspective === 'layers') {
            $.each(overlayInfo.layers, function(index,object) {
                $.each(object.svgIDs, function(i,id) {
                    $('.leaflet-overlay-pane svg.overlay path#' + currentState + '_' + id).attr('fill',colors[index]);
                });
            });
            
        } else if(currentPerspective === 'invariance') {
            $.each(overlayInfo.invariance, function(index,object) {
                $.each(object.svgIDs, function(i,id) {
                    $('.leaflet-overlay-pane svg.overlay path#' + currentState + '_' + id).attr('fill',colors[index]);
                });
            });
        }    
    } catch(e) {
        console.log('adjustOverlay failed');
    }
    
};


/***GUI Functionality***/

/*
 * function hideViews()
 * slides in the sideBox
 */
function hideViews() {
    //make sure two operations don't overlap
    ongoingViewChange = true;
    //get the distance that the sideBox needs to go back
    var dist = parseFloat($('#facsimileBox').css('right')) - 10;
    
    //just a global variable that can be asked if sideBox is visible
    showSideBox = false;
    //slide sideBox in
    $('#sideBox').animate({width:'-=' + dist});
    
    //increase width of facsimile area accordingly
    $('#facsimileBox').animate({right: '-=' + dist},function(){
        //when finished, allow other operations
        ongoingViewChange = false;
        
        //if a page is displayed, reset facsViewer positioning (important for centering)
        if(typeof facs._map !== 'undefined' && typeof facs._map.invalidateSize !== 'undefined')
            facs._map.invalidateSize();
    });
};

/*
 * function showView(viewID)
 * slides out the sideBox (if necessary) and selects a tab
 * the viewIDs are stored in an attribute @data-target on the tabs
 */
function showView(viewID) {
    //get ID of previously active tab
    var old = $('#viewTabs li.active')[0];
    //get old view
    var oldViewID = $(old).attr('data-target');
    //get tab of new view
    var next = $.grep($('#viewTabs li'),function(tab,i) {
       return $(tab).attr('data-target') === viewID; 
    })[0];
    var nextViewID = viewID;
    
    //stop processing if view is already changing
    if(ongoingViewChange)
        return;
    
    //prevent overlap of view changes
    ongoingViewChange = true;    
    
    //a different tab is clicked
    if(oldViewID !== nextViewID) {
        
        //the sidebox is already visible
        if(showSideBox) {
            
            //get view elements
            var oldView = $(oldViewID)[0];
            var nextView = $(nextViewID)[0];
            
            //toggle classes on tabs appropriately
            $(old).toggleClass('active');
            $(next).toggleClass('active');
            
            //fade out old view, then fade in new view, then reset ongoingViewChange
            $(oldView).fadeOut(100,function() {$(nextView).fadeIn(100,function(){ongoingViewChange = false;});});
        
        //the sidebox needs to be opened first
        } else {
        
            //get view elements
            var oldView = $(oldViewID)[0];
            var nextView = $(nextViewID)[0];
            
            //toggle classes on tabs appropriately
            $(old).toggleClass('active');
            $(next).toggleClass('active');
            
            //fade out old view, then fade in new view, then reset ongoingViewChange
            $(oldView).fadeOut(100,function() {$(nextView).fadeIn(100,function(){ongoingViewChange = false;});});
            
            //get 40% of window width in pixels, distance that sidebox will slide out
            var dist = $(window).width() * 0.4;
            
            //announce that sideBox is visible in global variable showSideBox
            showSideBox = true;
            
            //slide out sideBox
            $('#sideBox').animate({width:'+=' + dist});
            //decrease facsimile area accordingly
            $('#facsimileBox').animate({right: '+=' + dist},function(){
                if(typeof facs._map !== 'undefined' && typeof facs._map.invalidateSize !== 'undefined')
                    facs._map.invalidateSize();
            });
                        
        }
        
    //the same tab is clicked    
    } else {
        
        //the sidebox needs to be closed
        if(showSideBox) {
            
            hideViews();
        
        //the sidebox needs to be opened
        } else {
            
            //get 40% of window width in pixels, distance that sidebox will slide out
            var dist = $(window).width() * 0.4;
            
            //announce that sideBox is visible in global variable showSideBox
            showSideBox = true;
            
             //slide out sideBox
            $('#sideBox').animate({width:'+=' + dist});
            //decrease facsimile area accordingly
            $('#facsimileBox').animate({right: '+=' + dist},function(){
                if(typeof facs._map !== 'undefined' && typeof facs._map.invalidateSize !== 'undefined')
                    facs._map.invalidateSize();
            });
        }
    }    
    
    //reset ongoingViewChange
    ongoingViewChange = false;
};

/*
 * adds functionality to (un)fold page previews
 */
$('#pagePreview h1').on('click', function() {
    
    //distance that the pagePreview slides in an out
    var dist = 171;
    
    //if pagePreview is visible, slide it up
    if(showPreview) {
        showPreview = false;
        $('#pagePreview').animate({top:'-=' + dist});
        $('#mainBox').animate({top:'-=' + dist});    
    //else slide it down
    } else {
        showPreview = true;
        $('#pagePreview').animate({top:'+=' + dist});
        $('#mainBox').animate({top:'+=' + dist});
    }
    
    //if a page is displayed, reset facsViewer positioning (important for centering)
    if(typeof facs._map !== 'undefined' && typeof facs._map.invalidateSize !== 'undefined')
        facs._map.invalidateSize();
   
});

/*
 * adds functionality to select a view from the sidebox
 */
$('#viewTabs li').on('click', function(e) {
    
    //get previously active tab
    var old = $('#viewTabs li.active')[0];
    //get ID of previous tab
    var oldViewID = $(old).attr('data-target');
    
    //get new tab
    var next = e.currentTarget;
    //get ID of view to be openend
    var nextViewID = $(next).attr('data-target');
    
    //if sideBox is not visible or a different tab is active
    if(!showSideBox || oldViewID !== nextViewID) {
        showView(nextViewID);    
        
    //if sidebox is visible and active tab is clicked again    
    } else {
        hideViews();
    }
    
});

function triggerSwitchPerspective(perspective) {
      if(perspective === currentPerspective)
        return;
    
    if(['plain','layers','invariance'].indexOf(perspective) === -1) {
        console.log('"' + perspective + '" is not an allowed value for perspective (function triggerSwitchPerspective)');
        return;
    }
    
    $('#perspectiveForm input[value=' + perspective + ']').prop('checked',true);
    
};

function switchPerspective(perspective) {
    if(perspective === currentPerspective)
        return;
    
    if(['plain','layers','invariance'].indexOf(perspective) === -1) {
        console.log('"' + perspective + '" is not an allowed value for perspective (function switchPerspective)');
        return;
    }
    
    currentPerspective = perspective;
    
    $('.perspectiveBox').hide();
    $('.perspectiveBox.' + perspective).show();
    
    adjustOverlay();
    
};

/*
 * adds functionality to switch between different transcription perspectives
 */
$('#perspectiveTabs li').on('click', function(e) {
    
    //get previously active tab
    var old = $('#perspectiveTabs li.active')[0];
    $(old).toggleClass('active');
    //get ID of previous tab
    var oldViewID = $(old).attr('data-target');
    
    //get new tab
    var next = e.currentTarget;
    $(next).toggleClass('active');
    //get ID of view to be openend
    var nextViewID = $(next).attr('data-target');
    
    $(oldViewID).hide();
    $(nextViewID).show();
});


/*
 * adds functionality to open previous pages
 */
$('#prevPage').on('click',function(){
    //gets the position of the currently displayed page
    var index = jQuery.inArray(activePage,meiFile.pages);
    
    //if the current page has predecessors, show preceding page
    if(index > 0)
        showPage(meiFile.pages[index-1].id);
});

/*
 * adds functionality to open following page
 */
$('#nextPage').on('click',function(){

    //gets last page number
    var maxPage = meiFile.pages.length - 1;
    //gets number of current page
    var index = jQuery.inArray(activePage,meiFile.pages);
    
    //if current page has successors, show following page
    if(index < maxPage)
        showPage(meiFile.pages[index + 1].id);
});

/*
 * Hack: static link to page 14
 * todo[fix]: resolve that!
 */
$('#hintP14').on('click',function(){
    if(activePage.n == '14')
        return;
    
    showPage(meiFile.pages[13].id);
    
});

/*
 * Hack: static link to page 17 
 * todo[fix]: resolve that!
 */
$('#hintP17').on('click',function(){
    if(activePage.n == '17')
        return;
    
    showPage(meiFile.pages[16].id);
});

/*
 * functionality to toggle visibility of the about window
 */
$('#about, #aboutBox').on('click',function(){
    $('#aboutBox').fadeToggle();
    $('#facsimileBox, #sideBox').toggleClass('blurred');
});

//todo: reconstructing
/*$('#leaveReconstructModeBtn').on('click',function() {
    leaveReconstructMode();
});

function enterReconstructMode(stateID) {
    
    if(reconstructingStateID == stateID && reconstructing) {
        leaveReconstructMode();
        return;
    }
    
    reconstructingStateID = stateID;
    
    var state =  $.grep(meiFile.states[0].states,function(state,i) {
        //console.log('id: ' + state.id + ' ==? ' + stateID);
    
        return state.id == stateID;
    });
            
    var followingStates = $.grep(meiFile.states[0].states,function(refState,i) {
        //console.log('position: ' + refState.position + ' gt? ' + state[0].position);
        
        return refState.position > state[0].position;
    });
    
    $.each(followingStates, function(index,followingState) {
        //console.log(followingState);
        //console.log(overlays[state[0].position + index]);
        
        var layer = facs.activateLayer(overlays[state[0].position + index]);
        var tmp = layer._svgFile;
        
        $(tmp).children('path').attr('fill',paperColor).attr('opacity','1');
        
        //console.log(layer);
    });
    
    
    if(!reconstructing) {
        $('.leaflet-top.leaflet-right').fadeOut(function(){
            reconstructing = true;
            $('#reconstructionHint .stateLabel').html(state[0].label);
            $('#reconstructionHint').fadeIn();
        });
    } else {
        $('#reconstructionHint .stateLabel').html(state[0].label);
    }
};

function leaveReconstructMode() {
    reconstructing = false;
    reconstructingStateID = '';
    $('#reconstructionHint').fadeOut(function(){
        $('#reconstructionHint .stateLabel').html('');
        $('.leaflet-top.leaflet-right').fadeIn();
    });
    $('.revertBtn.active .fa').addClass('fa-eye').removeClass('fa-eye-slash');
    $('.revertBtn.active').removeClass('active');
};*/


/*
 * listener on fullscreen button
 */
$('#fullscreenButton').on('click', function() {
    toggleFullscreen();
});

/*
 * listener on fullscreenmode which toggles button on and off
 */
$(document).on('fullscreenchange webkitfullscreenchange mozfullscreenchange MSFullscreenChange', function() {
    $('#fullscreenButton i.fa').toggleClass('fa-toggle-off').toggleClass('fa-toggle-on');
});

/*
 * function toggleFullscreen
 * activates fullscreen mode on various browsers
 * 
 * todo: if fullscreenmode is not supported by current means, hide fullscreenButton
 */
function toggleFullscreen() {
    //checks if fullscreenMode is supported
    if (
        document.fullscreenEnabled ||
        document.webkitFullscreenEnabled ||
        document.mozFullScreenEnabled ||
        document.msFullscreenEnabled
    ) {
        
        //if app is not in fullscreen mode
        if(
            !document.fullscreen &&
            !document.webkitFullscreen &&
            !document.mozFullScreen &&
            !document.msFullscreen
        ) {
            //request fullscreen, depending on browser
            if (document.fullscreenEnabled) {        
                document.getElementsByTagName('body')[0].requestFullscreen();         
            } else if (document.webkitFullscreenEnabled) {
                document.getElementsByTagName('body')[0].webkitRequestFullscreen();
            } else if (document.mozFullScreenEnabled) {
                document.getElementsByTagName('body')[0].mozRequestFullScreen();
            } else if (document.msFullscreenEnabled) {
                document.getElementsByTagName('body')[0].msRequestFullscreen();
            }
            
        // app is already in fullscreen mode    
        } else {
            //leave fullscreen, depending on browser (also available by 'esc' key as browser default)
            if (document.exitFullscreen) {
                document.exitFullscreen();
            } else if (document.webkitExitFullscreen) {
                document.webkitExitFullscreen();
            } else if (document.mozCancelFullScreen) {
                document.mozCancelFullScreen();
            } else if (document.msExitFullscreen) {
                document.msExitFullscreen();
            }
            
        }
        
        // reset size of facsimile (important for calculating center etc) 
        if(typeof facs._map !== 'undefined' && typeof facs._map.invalidateSize !== 'undefined')
            facs._map.invalidateSize();
    }
};

/*
 * function getBaseLanguage()
 * identifies language of browser (should work on recent Firefox, Chrome, Safari and IE11)
 */
function getBaseLanguage() {

    var prefLang = 'de';
    if (typeof navigator.language === 'string' && navigator.language.length > 0)
        prefLang = navigator.language;
    else if(typeof navigator.browserLanguage === 'string' && navigator.browserLanguage.length > 0)
        prefLang = navigator.browserLanguage;
        
        
    getLangFile(prefLang);
};

/*
 * function getLangFile(lang)
 * 
 * gets a JSON file with all language strings from the server
 */
function getLangFile(targetLang) {
    
    new jQuery.getJSON('resources/xql/getLangFile.xql',{prefLang: targetLang},function(data) {
        
        console.log('lang (wanted): ' + targetLang);
        
        lang = data.lang;
        
        console.log('data.lang: ' + data.lang);
        console.log('lang (new): ' + lang);
        
        langFile = data.localization;
        
        $('*[data-i18n-text], *[data-i18n-title]').each(function(index) {
            localize($(this));
        });
        
        facs.setLanguage(data.lang);
    });
    
};

/*
 * function localize(elem)
 * 
 * gets the localization for the specified element, based on the currently selected langFile
 */
function localize(elem) {
    
    if(typeof $(elem).attr('data-i18n-text') !== 'undefined') {
        var key = $(elem).attr('data-i18n-text');
        $(elem).html(langFile[key]);    
    }
    
    if(typeof $(elem).attr('data-i18n-title') !== 'undefined') {
        var key = $(elem).attr('data-i18n-title');
        $(elem).attr('title',langFile[key]);    
    }
    
    /*return elem;*/
};

/*
 * register listeners for language selection
 */
$('#langSelectEN').on('click', function() {
    getLangFile('en'); 
});
$('#langSelectDE').on('click', function() {
    getLangFile('de'); 
});


/*
 * start of application
 */
getFeatures();
getBaseLanguage();
