/* 
 *  Two Channel Counting
 *  Counts 2 channels (GFP, mCherry) of BD Pathway images
 *  
 *  Code by Lachlan Whitehead (whitehead@wehi.edu.au)
 *  Nov 2013
 *  
 */


/* 
 *  Runs on a directory of files generate by BD Pathway and sorted
 *  using BD_Pathway_Sorter.py
 *  
 *  Fairly basic segmentation, includes average size measurements (in pixels,
 *  as the calibration will change depending on objective)
 *  
 */


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//Set up variables (add any that are needed dir1,dir2,list, and fs are all requichannel2 by functions);
var dir1="C:\\";
var dir2="C:\\";
var list = newArray();
var fs = File.separator();
var GENERATE_MASKS = true;

run("Set Measurements...", "area limit channel2irect=None decimal=3"); //<- for measuring area

//Batch a directory?
batchFlag = Batch_Or_Not();

//Get channels - so far this script will work on 1 or two channels
channels = getChannels(list);
print("There are "+channels.length+" channels. ");
print("And they are ");
Array.print(channels);

exp_name = File.getName(dir1);
print("And the experiment is called: " + exp_name);


channel1 = channels[0];
if(channels.length==2){
	channel2 = channels[1];
}else{
	//If there's no channel2, just set these variables to zero
	//It's a hack but it's quick and works
	channel2_count = 0;
	channel2_avg_size = 0;
	channel2 = "empty";
	channel2_results = 0;
	count=0;
}




//Setup custom results table 
Table_Heading = "" + exp_name + " Cell Counts";
columns = newArray("Well",channel1+" +ve", "Mean "+channel1+" Cell Size",  channel2+ " +ve", "Mean "+channel2+" Cell Size", "Double pos");
table = generateTable(Table_Heading,columns);

//Setup custom 384 well plate maps
channel1_count_array = generate384WellPlateArray();
if(channels.length==2){
	channel2_count_array = generate384WellPlateArray();
	double_count_array = generate384WellPlateArray();
}

//setBatchMode(true);
//Begin the Loop!
for(i=0;i<list.length;i++){
	
	//If we're batching, and it's not a directory, open the next file 
	//This particular macro will probably break if we're not batching
	if(!File.isDirectory(dir1+list[i])){
		if(batchFlag){
			open(dir1+list[i]);
		}

		//////////////////////
		//Do things in here //
		//////////////////////
		channel1_fname = list[i];
		if(matches(channel1_fname,".*"+channel1+".*")){
			well = substring(channel1_fname,5,9);
			row = substring(well,0,1);
			col = substring(well,1,lengthOf(well));
			file_prefix = substring(channel1_fname,0,9);
			file_suffix = substring(channel1_fname,lengthOf(channel1_fname)-18,lengthOf(channel1_fname));
			channel2_fname = file_prefix + channel2 + file_suffix;

			channel1_results = segment_channel(channel1_fname,50,100,15,channel1_count_array);
			
			if(channels.length==2){
			open(dir1+channel2_fname);
			
			channel2_results = segment_channel(channel2_fname,50,65,15,channel2_count_array);

				//If double pos count:
				selectWindow("ROI Manager");
				run("Close");
		
				
				imageCalculator("AND create", channel1_fname+"_mask", channel2_fname+"_mask");
				//selectWindow("Result of Well B002mCherry mkk - n000000.tif_mask");
				setAutoThreshold("Default dark");
				run("Analyze Particles...", "size=15-Infinity pixel circularity=0.5-1.00 show=Nothing display clear add");
				count = roiManager("Count");
				print("Double pos in " + row + toString(col) + " = " + count);

				writeTo384WellArray(double_count_array,row,col,count);}
					


			resultArray = Array.concat(well,channel1_results,channel2_results,count);
			logResults(table,resultArray);
			
		}

			//Clean up only if we're batching, if not just leave everything open
			//Consider closing superflous images as you go along
			if(batchFlag){
				run("Close All");
			}
	}	
	
}
run("Close All");




printArrayTable("" + exp_name + " " + channel1 + " counts",channel1_count_array);
printArrayTable("" + exp_name + " " + channel2 + " counts",channel2_count_array);
printArrayTable("" + exp_name + " Double counts",double_count_array);

ratio_array = newArray(channel1_count_array.length);
for(i=0;i<channel1_count_array.length;i++){
	ratio_array[i]=channel2_count_array[i]/channel1_count_array[i];
}

printArrayTable("" + exp_name+ " Ratio",ratio_array);



/* PUT SAVE TABLE INTO FUNCTION */
selectWindow(Table_Heading);
if(batchFlag){
	saveTable(Table_Heading);
	saveTable("" + exp_name + " " + channel1 + " counts");
	saveTable("" + exp_name + " " + channel2 + " counts");
	saveTable("" + exp_name + " Double counts");
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
			end = indexOf(fileList[i],"mkk")-1;
			start = 9;
			channel = substring(fileList[i],start,end);
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


function mainMenu(channels){

	/* HELP for  menu */
  	  help = "<html>"
	     +"<h3>Actin Bunching Measurement Help</h3>"
	     +"</html>";
	
  	Dialog.create("BD Pathway Cell Counter");
 	
	Dialog.addMessage("Options:");
  	Dialog.addCheckbox("Generate Output Masks", true);
//		Dialog.setInsets(0, 40, 0);
   	Dialog.addMessage(channels[0] + " Segmentation Options");
	Dialog.addNumber("Rolling ball radius",50,0,3,"Pixels");
	Dialog.addNumber(channels[0] + " Threshold",150,0,3,"");
  	if(channels.length>1){
  		Dialog.addMessage(channels[1] + " Segmentation Options");
		Dialog.addNumber("Rolling ball radius",50,0,3,"Pixels");
		Dialog.addNumber(channels[1] + " Threshold",150,0,3,"");
  	}
  	
  	
  	Dialog.addMessage("");
	//Dialog.addHelp("http://en.wikipedia.org/wiki/Special:Random");
	Dialog.addHelp(help);

	Dialog.show();

	GENERATE_MASKS = Dialog.getCheckbox();
	CHANNEL1_RB_RADIUS = Dialog.getNumber();
	CHANNEL1_THRESHOLD = Dialog.getNumber();
	IF(channels.length>1){
		CHANNEL2_RB_RADIUS = Dialog.getNumber();
		CHANNEL2_THRESHOLD = Dialog.getNumber();
	}
}


function generate96WellPlateArray(){
	x=12;
	y=8;		// 96 well plate dimensions
	thing = newArray(x*y);
	return thing;
}

function generate384WellPlateArray(){
	x=24;
	y=16;		// 96 well plate dimensions
	thing = newArray(x*y);
	return thing;
}

function writeTo96WellArray(ArrayName,row,column,value){
	if(column>12){showMessage("You've made a terrible mistake");exit;}
	r = rowToIndex(row);
	if(r>7){showMessage("You've made a terrible mistake");exit;}
	c = column-1;		   //index from 0
	ArrayName[c+r*12] = value; //12 for width of 96 well plate
}

function writeTo384WellArray(ArrayName,row,column,value){
	if(column>24){showMessage("You've made a terrible mistake");exit;}
	r = rowToIndex(row);
	if(r>15){showMessage("You've made a terrible mistake");exit;} 
	c = parseInt(column)-1;	   //index from 0
	ArrayName[c+r*24] = value; //12 for width of 384 well plate
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


function segment_channel(filename,bg_rad,low_thresh,min_size,count_platemap_name){
	well = substring(filename,5,9);
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
	writeTo384WellArray(count_platemap_name,row,col,count);
	//Summarise results
	resultsArray=newArray();
	for(j=0;j<count;j++){
		resultsArray=Array.concat(resultsArray,getResult("Area",j));
	};
	Array.getStatistics(resultsArray,min,max,avg,stDev);
	avg_size = avg;
	count_and_size = newArray(count,avg_size);
	return count_and_size;	

	if(GENERATE_MASKS){
			selectWindow("Temp_Channel");
			roiManager("Show All without labels");
			run("Flatten");
			saveAs("TIF",dir2+filename);
	}
	
}


