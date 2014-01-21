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

function logResults(tablename,results_array){
	resultString = results_array[0]; //First column
	//Build the rest of the columns
	for(i=1;i<results_array.length;i++){
		resultString = toString(resultString + " \t " + results_array[i]);
	}
	//Populate table
	print(tablename,resultString);
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
	c = column-1;		   //index from 0
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


platemap = generate96WellPlateArray();
anotherPlateMap = generate384WellPlateArray();
writeTo96WellArray(platemap,"a",12,100);
writeTo384WellArray(anotherPlateMap,"g",24,100);
printArrayTable("Expname Mean",platemap);
printArrayTable("asdf2",anotherPlateMap);


