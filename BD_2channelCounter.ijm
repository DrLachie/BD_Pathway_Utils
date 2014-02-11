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

run("Set Measurements...", "area limit channel2irect=None decimal=3"); //<- for measuring area

//Batch a directory?
batchFlag = Batch_Or_Not();

//Get channels - so far this script will work on 1 or two channels
channels = getChannels(list);
print("There are "+channels.length+" channels. ");
print("And they are ");
Array.print(channels);

channel1 = channels[0];
if(channels.length==2){
	channel2 = channels[1];
}else{
	//If there's no channel2, just set these variables to zero
	//It's a hack but it's quick and works
	channel2_count = 0;
	channel2_avg_size = 0;
	channel2 = "empty";
}




//Setup custom results table 
Table_Heading = "Cell Counts";
columns = newArray("Well",channel1+" +ve", channel2+ " +ve", "Mean "+channel1+" Cell Size", "Mean "+channel2+" Cell Size");
table = generateTable(Table_Heading,columns);

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
			//Get Well and channel2 file name
			well = substring(channel1_fname,5,9);
			file_prefix = substring(channel1_fname,0,9);
			file_suffix = substring(channel1_fname,lengthOf(channel1_fname)-18,lengthOf(channel1_fname));
			channel2_fname = file_prefix + channel2 + file_suffix;
		
		
			//CHANNEL 1 SEGMENTATION AND COUNT
			open(dir1+channel1_fname);
			run("Properties...", "unit=pixels pixel_width=1 pixel_height=1 voxel_depth=1");
			makeRectangle(687, 381, 2397, 2232);
			run("Duplicate...", "title=[channel1_Channel]");
			run("Duplicate...", "title=[Asdf]");
			//run("Smooth");
			run("Subtract Background...", "rolling=50");
			setThreshold(100,4095);
			run("Convert to Mask");
			run("Watershed");
			//setTool("zoom");
			roiManager("Show All with labels");
			roiManager("Show All");
			run("Analyze Particles...", "size=50-Infinity pixel circularity=0.50-1.00 show=Nothing display clear add");
			channel1_count = nResults();.
				//Summarise results
				count = nResults();
				resultsArray=newArray();
				for(j=0;j<count;j++){
					resultsArray=Array.concat(resultsArray,getResult("Area",j));
				};
				Array.getStatistics(resultsArray,min,max,avg,stDev);
				channel1_avg_size = avg;
			
			selectWindow("channel1_Channel");
			roiManager("Show All without labels");
			run("Flatten");
			saveAs("TIF",dir2+channel1_fname);
			
			//CHANNEL 2 SEGMENTATION AND COUNT - if channel 2 exists
			if(channels.length==2){
				open(dir1+channel2_fname);
				run("Properties...", "unit=pixels pixel_width=1 pixel_height=1 voxel_depth=1");
				makeRectangle(687, 381, 2397, 2232);
				run("Duplicate...", "title=[channel2_Channel]");
				run("Duplicate...", "title=[Asdf]");
				run("Subtract Background...", "rolling=50");
				setThreshold(100,4095);
				run("Convert to Mask");
				run("Watershed");
				//setTool("zoom");
				roiManager("Show All without labels");
				roiManager("Show All");
				run("Analyze Particles...", "size=25-Infinity pixel circularity=0.50-1.00 show=Nothing display clear add");
				channel2_count = nResults();
								
			//Summarise results
				count = nResults();
				resultsArray=newArray();
				for(j=0;j<count;j++){
					resultsArray=Array.concat(resultsArray,getResult("Area",j));
				};
				Array.getStatistics(resultsArray,min,max,avg,stDev);
				channel2_avg_size = avg;
				
				selectWindow("channel2_Channel");
				roiManager("Show All without labels");
				run("Flatten");
				saveAs("TIF",dir2+channel2_fname);
			
			}

			
	
			resultArray = newArray(well,channel1_count,channel2_count,channel1_avg_size,channel2_avg_size);
			logResults(table,resultArray);
			
			//Clean up only if we're batching, if not just leave everything open
			//Consider closing superflous images as you go along
			if(batchFlag){
				run("Close All");
			}
		}	
	}
}
run("Close All");

selectWindow(Table_Heading);
if(batchFlag){
	if(File.exists(dir2+Table_Heading+".txt")){
		overwrite=getBoolean("Warning\nResult table file alread exists, overwrite?");
			if(overwrite==1){
				saveAs("Text",dir2+Table_Heading+".txt");
			}
	}else{
		saveAs("Text",dir2+Table_Heading+".txt");
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


