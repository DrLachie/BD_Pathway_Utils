print("\\Clear");

//Set up variables (add any that are needed dir1,dir2,list, and fs are all requichannel2 by functions);
var dir1="C:\\";
var dir2="C:\\";
var list = newArray();
var fs = File.separator();
var wells = newArray();
var GENERATE_MASKS = true;
var SETUP_WELL = "A01";
var USE_ROI = true;
var HAS_ROI = false;
var selection_Array = newArray(0,0,1,1);
var CH0_BG_RAD = 50;
var CH1_BG_RAD = 50;
var CHANNEL1_MIN_SIZE = 15;
var CHANNEL1_MIN_SIZE = 15;
var PLATE_FORMAT = 96;


//Batch a directory?
batchFlag = Batch_Or_Not();

//Get channels - so far this script will work on 1 or two channels
channels = getChannels(list);
nChannels = channels.length;
print("There are "+nChannels+" channels. ");
print("And they are ");
Array.print(channels);

exp_name = File.getName(dir1);
print("And the experiment is called: " + exp_name);

wells = getWells(list);
print("And these are the wells");
Array.print(wells);



mainMenu(channels);

print("And the plate format is " + PLATE_FORMAT);

if(wells.length>PLATE_FORMAT){
	exit("Wrong plate format selected");
}



//Table_Heading = "Cell Counts";
//columns = newArray("Well",channels[0]+" +ve");
//table = generateTable(Table_Heading,columns);



channel0_settings = setup_segmentation(channels[0],SETUP_WELL,CH0_BG_RAD,15);
print("Segmentation settings for "+channels[0]+":");
Array.print(channel0_settings);

if(nChannels>1){
	channel1_settings = setup_segmentation(channels[1],SETUP_WELL,CH1_BG_RAD,15);
	print("Segmentation settings for "+channels[1]+":");
	Array.print(channel1_settings);
}


if(PLATE_FORMAT==96){
	ch0platemap = generate96WellPlateArray("ch0_count_heatmap");
	if(channels.length==2){
		ch1platemap = generate96WellPlateArray("ch1_count_heatmap");
		ratioplatemap = generate96WellPlateArray("ratio_heatmap");
	}
}else{
	ch0platemap = generate384WellPlateArray("ch0_count_heatmap");
	if(channels.length==2){
		ch1platemap = generate384WellPlateArray("ch1_count_heatmap");
		ratioplatemap = generate384WellPlateArray("ratio_heatmap");
	}
}




setBatchMode(true);
for(j=0;j<list.length;j++){
	if(isOpen("ROI Manager")){
		selectWindow("ROI Manager");
		run("Close");
	}
	if(!File.isDirectory(dir1+list[j]) && endsWith(list[j],"tif")){
		fname = list[j];
		open(dir1+list[j]);
		if(matches(fname,".*"+channels[0]+".*")){
			channel0_count_and_size = segment_channel(fname,channel0_settings[1],channel0_settings[0],channel0_settings[2],ch0platemap,"ch0_count_heatmap");
			well = substring(list[j],5,9);
			channel0_count = channel0_count_and_size[0];
		}else{
			if(matches(fname,".*"+channels[1]+".*")){
				print("DOING CHANNEL 1 " + fname);
				channel1_count_and_size = segment_channel(fname,channel1_settings[1],channel1_settings[0],channel1_settings[2],ch1platemap,"ch1_count_heatmap");
				well = substring(list[j],5,9);
				channel1_count = channel1_count_and_size[0];
			}
		}
	}	
		
		//resultArray = newArray(well,channel0_count);
		//logResults(table,resultArray);
}


printArrayTable("Channel 0 Counts",ch0platemap);
if(nChannels>1){
	printArrayTable("Channel 1 Counts",ch1platemap);
}

//saveTable("Count Table");
saveTable("Channel 0 Counts");
if(nChannels>1){
	saveTable("Channel 0 Counts");
}	


selectWindow("ch0_count_heatmap");
do_3d_plot();
if(nChannels>1){
selectWindow("ch1_count_heatmap");
do_3d_plot();
}
////////////////////////////////////////////////////
// Functions 					  //
////////////////////////////////////////////////////




//Generate a custom table
//Give it a title and an array of headings
//Returns the name required by the logResults function
function generateTable(tableName,column_headings){
	if(isOpen(tableName)){
		selectWindow(tableName);
		run("Close");
	}
	tableTitle=tableName;
	tableTitle2="["+tableTitle+"]";
	run("Table...","name="+tableTitle2+" width=600 height=250");
	newstring = "\\Headings:"+column_headings[0];
	for(i=1;i<column_headings.length;i++){
			newstring = newstring +" \t " + column_headings[i];
	}
	print(tableTitle2,newstring);
	return tableTitle2;
}


//Log the results into the custom table
//Takes the output table name from the generateTable funciton and an array of resuts
//No checking is done to make sure the right number of columns etc. Do that yourself
function logResults(tablename,results_array){
	resultString = results_array[0]; //First column
	//Build the rest of the columns
	for(i=1;i<results_array.length;i++){
		resultString = toString(resultString + " \t " + results_array[i]);
	}
	//Populate table
	print(tablename,resultString);
}

function saveTable(temp_tablename){
	selectWindow(temp_tablename);
	if(File.exists(dir2+temp_tablename+".txt")){
		overwrite=getBoolean("Warning\nResult table \""+temp_tablename+"\" file alread exists, overwrite?");
			if(overwrite==1){
				saveAs("Text",dir2+temp_tablename+".txt");
			}
	}else{
		saveAs("Text",dir2+temp_tablename+".txt");
	}
}

//Choose what to batch on
function Batch_Or_Not(){
	// If an image is open, run on that
	if(nImages == 1){
		fname = getInfo("image.filename");
		dir1 = getInfo("image.directory");
		dir2 = dir1 + "output" + fs;
		list=newArray("temp");
		list[0] = fname;
		batchFlag = false;
	// If more than one is, choose one
	}else if(nImages > 1){
		waitForUser("Select which image you want to run on");
		fname = getInfo("image.filename");
		dir1 = getInfo("image.directory");
		dir2 = dir1 + "output" + fs;
		list=newArray("temp");
		list[0] = fname;
		batchFlag = false;	
	// If nothing is open, batch a directory
	}else{
		dir1 = getDirectory("Select source directory");
		list= getFileList(dir1);
		dir2 = dir1 + "output" + fs;
		batchFlag = true;
	}

	if(!File.exists(dir2)){
		File.makeDirectory(dir2);
	}
	return(batchFlag);
}


//Get the channels from the file list. Returns an array containing the channel labels
//Based on the assumption that BD Files will always be of the structure "Well A001[channel]mkk - n000001.tif";
function getChannels(fileList){

	channelList=newArray();

	for(i=0;i<fileList.length;i++){
		if(endsWith(fileList[i],".tif")){
			currentwell = substring(fileList[i],5,9);
			last_character = substring(currentwell,lengthOf(currentwell)-1,lengthOf(currentwell));
			checker = parseInt(last_character);
			//print(checker);
			start=9;
			if(isNaN(checker)){
				//print("aww");
				start = 8;
			}
			end = indexOf(fileList[i],"- n0")-1;

			channel = substring(fileList[i],start,end);
			//channel = substring(channel,0,indexOf(channel," "));
			channelList = Array.concat(channelList,channel);
		}
	}
	
	Array.sort(channelList);
	channels = newArray(channelList[0]);
	
	
	for(i=1;i<channelList.length;i++){
		if(channelList[i]!=channelList[i-1]){
			channels = Array.concat(channels,channelList[i]);	
		}
	}	

	return channels;
}

function getWells(filelist){
	well_array = newArray();
	for(i=0;i<filelist.length;i++){
		if(endsWith(filelist[i],".tif")){
			currentwell = substring(filelist[i],5,9);
			last_character = substring(currentwell,lengthOf(currentwell)-1,lengthOf(currentwell));
			checker = parseInt(last_character);
			//print(checker);
			if(isNaN(checker)){
				//print("aww");
				currentwell = substring(currentwell,0,lengthOf(currentwell)-1);
			}
			well_array = Array.concat(well_array,currentwell);
			//print(currentwell);
		}
	}
	return well_array;
}


function setup_segmentation(channel,well,bg_sub_value, min_size){
	open(dir1+fs+"Well "+well+channel+" - n000000.tif");
	original = getTitle();
	if(USE_ROI & !HAS_ROI){
		run("Enhance Contrast", "saturated=0.35");
		setTool("Rectangle");
		waitForUser("Draw ROI");
		getSelectionBounds(x, y, width, height);
		selection_Array = newArray(x,y,width,height);
		HAS_ROI=true;
	}else{
		if(USE_ROI){
			makeRectangle(selection_Array[0], selection_Array[1], selection_Array[2], selection_Array[3]);
		}
	}
	run("Duplicate...","title=smaller");
	run("Duplicate...","title=for_thresholding");
	run("Subtract Background...", "rolling="+bg_sub_value); 

	run("Threshold...");
	waitForUser("adjust threshold until you're happy");
	getThreshold(min,max);
	run("Convert to Mask");
	run("Watershed");
	//setTool("zoom");
	roiManager("Show All with labels");
	roiManager("Show All");
	run("Analyze Particles...", "size="+min_size+"-Infinity pixel circularity=0.50-1.00 show=Nothing display clear add");
	selectWindow("smaller");
	run("Enhance Contrast", "saturated=0.35");
	roiManager("Show All without labels");
	roiManager("Show All");
	all_is_well = getBoolean("Happy?");
	if(all_is_well){
		channel_seg_settings = newArray(min, bg_sub_value, min_size);
		run("Close All");
		return channel_seg_settings;
	}else{
		run("Close All");
		bg_sub_value = getNumber("Adjust bacgkround subtraction radius?",bg_sub_value);
		temp = setup_segmentation(channel,well,bg_sub_value,min_size);
		return temp;
	}
}


function mainMenu(channels){

	/* HELP for  menu */
  	  help = "<html>"
	     +"<h3>Actin Bunching Measurement Help</h3>"
	     +"</html>";
	
  	Dialog.create("BD Pathway Cell Counter");
 	
	Dialog.addMessage("Options:");
	if(wells.length>96){	
		Dialog.addRadioButtonGroup("Plate Format", newArray("96 Well Plate", "384 Well Plate"), 1, 2, "384 Well Plate"); 
	}else{
  		Dialog.addRadioButtonGroup("Plate Format", newArray("96 Well Plate", "384 Well Plate"), 1, 2, "96 Well Plate"); 
  	}
  	
  	Dialog.addCheckbox("Generate Output Masks", true);
//		Dialog.setInsets(0, 40, 0);
   	Dialog.addChoice("Which well to set up on", wells);
   	Dialog.addCheckbox("Use ROI?",false)
   	Dialog.addMessage(channels[0] + " Segmentation Options");
	Dialog.addNumber("Rolling ball radius",50,0,3,"Pixels");
	Dialog.addNumber(channels[0] + " Minimum Size",15,0,3,"");
	if(channels.length>1){
  		Dialog.addMessage(channels[1] + " Segmentation Options");
		Dialog.addNumber("Rolling ball radius",50,0,3,"Pixels");
		Dialog.addNumber(channels[1] + " Minimum Size",15,0,3,"");
  	}
  	
  	
  	Dialog.addMessage("");
	//Dialog.addHelp("http://en.wikipedia.org/wiki/Special:Random");
	Dialog.addHelp(help);

	Dialog.show();

	plate_string = Dialog.getRadioButton();
	GENERATE_MASKS = Dialog.getCheckbox();
	SETUP_WELL = Dialog.getChoice();
	USE_ROI = Dialog.getCheckbox();
	CH0_BG_RAD = Dialog.getNumber();
	CHANNEL0_MIN_SIZE = Dialog.getNumber();
	
	if(channels.length>1){
		CH1_BG_RAD = Dialog.getNumber();
		CHANNEL1_MIN_SIZE = Dialog.getNumber();
	}

	if(plate_string == "96 Well Plate"){
		PLATE_FORMAT = 96;
	}else{
		PLATE_FORMAT = 384;
	}
}




function generate96WellPlateArray(Heatmap_name){
	x=12;
	y=8;		// 96 well plate dimensions
	thing = newArray(x*y);
	newImage(Heatmap_name, "16-bit black", 12, 8, 1);
		run("Set... ", "zoom=3200 x=2 y=3 width=12 height=8");
		run("Fire");
	return thing;
}

function generate384WellPlateArray(Heatmap_name){
	x=24;
	y=16;		// 384 well plate dimensions
	thing = newArray(x*y);
		//generate_heatmap (if requested?);
		newImage(Heatmap_name, "16-bit black", 24, 16, 1);
		run("Set... ", "zoom=3200 x=4 y=6 width=24 height=16");
		run("Fire");
	return thing;
}

function writeTo96WellArray(ArrayName,Heatmap_name,row,column,value){
	if(column>12){showMessage("You've made a terrible mistake");exit;}
	r = rowToIndex(row);
	if(r>7){showMessage("You've made a terrible mistake");exit;}
	c = parseInt(column)-1;		   //index from 0
	ArrayName[c+r*12] = value; //12 for width of 96 well plate
	selectWindow(Heatmap_name);
	setPixel(c,r,value);
	getStatistics(area, mean, min, max, std, histogram);
	setMinAndMax(0,max);
	
}

function writeTo384WellArray(ArrayName,Heatmap_name,row,column,value){
	if(column>24){showMessage("You've made a terrible mistake");exit;}
	r = rowToIndex(row);
	if(r>15){showMessage("You've made a terrible mistake");exit;} 
	c = parseInt(column)-1;	   //index from 0
	ArrayName[c+r*24] = value; //24 for width of 384 well plate
	selectWindow(Heatmap_name);
	setPixel(c,r,value);
	print(Heatmap_name,c,r,value);
	getStatistics(area, mean, min, max, std, histogram);
	setMinAndMax(0,max);
}

function rowToIndex(row){
	index = parseInt(row,36)-10;
	return index	
}

function indexToRow(index){
	if(index==1){row="a";}
	if(index==2){row="b";}
	if(index==3){row="c";}
	if(index==4){row="d";}
	if(index==5){row="e";}
	if(index==6){row="f";}
	if(index==7){row="g";}
	if(index==8){row="h";}
	if(index==9){row="i";}
	if(index==10){row="j";}
	if(index==11){row="k";}
	if(index==12){row="l";}
	if(index==13){row="m";}
	if(index==14){row="n";}
	if(index==15){row="o";}
	if(index==16){row="p";}
	//print(row);
	return row;	
	
}

function printArrayTable(Table_Heading,arrayname){
	if(arrayname.length==96){
		columns = newArray("Row");
		for(i=0;i<12;i++){
			columns=Array.concat(columns,i+1);
		}
		table = generateTable(Table_Heading,columns);
		for(i=0;i<8;i++){
			row = indexToRow(i+1);
			
			newline=newArray(""+row+"");
			for(j=0;j<12;j++){
				newline=Array.concat(newline,arrayname[j+i*12]);
				}
			logResults(table,newline);
		}
	}
	if(arrayname.length==384){
		columns = newArray("Row");
		for(i=0;i<24;i++){
			columns=Array.concat(columns,i+1);
		}
		table = generateTable(Table_Heading,columns);
		for(i=0;i<16;i++){
			row = indexToRow(i+1);
			
			newline=newArray(""+row+"");
			for(j=0;j<24;j++){
				newline=Array.concat(newline,arrayname[j+i*24]);
				}
			logResults(table,newline);
		}
	}
}


function segment_channel(filename,bg_rad,low_thresh,min_size,count_platemap_name,Heatmap_name){
	if(PLATE_FORMAT == 96){
		well = substring(filename,5,8);
	}else{
		well = substring(filename,5,9);		
	}
	row = substring(well,0,1);
	col = substring(well,1,lengthOf(well));

	run("Properties...", "unit=pixels pixel_width=1 pixel_height=1 voxel_depth=1");
	makeRectangle(762, 405, 2196, 2160);
	run("Duplicate...", "title=[Temp_Channel]");
	run("Duplicate...", "title=[Asdf]");
	//run("Smooth");
	run("Subtract Background...", "rolling="+bg_rad);
	setThreshold(low_thresh,4095);
	run("Convert to Mask");
	run("Watershed");
	rename(filename+"_mask");
	//setTool("zoom");
	roiManager("Show All with labels");
	roiManager("Show All");
	run("Analyze Particles...", "size=15-Infinity pixel circularity=0.50-1.00 show=Nothing display clear add");
	count = nResults();
	if(PLATE_FORMAT==96){
		writeTo96WellArray(count_platemap_name,Heatmap_name,row,col,count);
	}else{
		writeTo384WellArray(count_platemap_name,Heatmap_name,row,col,count);
	}
	//Summarise results
	resultsArray=newArray();
	for(j=0;j<count;j++){
		resultsArray=Array.concat(resultsArray,getResult("Area",j));
	};
	Array.getStatistics(resultsArray,min,max,avg,stDev);
	avg_size = avg;
	count_and_size = newArray(count,avg_size);
	
	if(GENERATE_MASKS){
		selectWindow("Temp_Channel");
		roiManager("Show All without labels");
		run("Flatten");
		saveAs("TIF",dir2+filename);
	}

	close(fname);
	close(fname+"_mask");
	close("Temp_Channel");

	return count_and_size;	
	
}

function do_3d_plot(){
	setBatchMode(false);
	plugin_dir = getDirectory("plugins");
	print("3d plugin exists");
	run("Interactive 3D Surface Plot",      "plotType=3 smooth=0 colorType=3 snapshot=1 rotationZ=0 scaleZ=2 rotationX=0 perspective=1 scale=1.8 drawAxes=0 drawLines=0 drawText=0 drawLegend=0");
	//makeRectangle(12, 88, 637, 423);
//run("Crop");


}
