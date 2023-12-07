/*
	29-10-20
	Written by Esther Wershof and David Barry
*/

/*
 INSTRUCTIONS:
 - It's a good idea to read the documentation and try the tutorial first to get a feel for what it does
 - If you want to start a new .ijm script (eg for testing a specific function) Click File->New, then Language->IJ1 Macro
 - All built in macro functions can be found here: https://imagej.nih.gov/ij/developer/macro/functions.html
 - setBatchMode(true) is used to suppress the output ie if you do something to many files, don't want to open them all.
 - The code for computing HDM is called QBS = QuantBlackSpace. The image is processed so that most pixels are black (=0) with any nonzero pixels
 	corresponding to areas of high-density matrix. The output is a separate _resultsHDM.csv file which gives the proportion of black pixels.
 	HDM is then equal to 1-numberBlackPixels.
 - anamorfProperties.xml is a .xml file that input additional parameters for anamorf to run
 - Functions are all at the bottom of the script
 - Functions to be performed in batch mode ie on all files in a folder have this structure:
 
 function doSomethingToFolder(input,output) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i])) // ie if you have a folder within a folder, it goes down another level
{
			doSomethingToFolder(input + File.separator + list[i]);
		} else {
			doSomethingToFILE(input, output, list[i]);
		}
	}
}

 */

/*
 ------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
	0. BEFORE IT GETS STARTED...
-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
*/
run("Options...", "iterations=1 count=1");

// closes and clears anything already open
run("Close All");

if (isOpen("Log")) { 
 selectWindow("Log"); 
 run("Close"); 
} 

// declaring global variables
var CONTRAST_SATURATION = "Contrast Saturation";
var MIN_LINE_WIDTH = "Min Line Width";
var MAX_LINE_WIDTH = "Max Line Width";
var MIN_CURVATURE_WINDOW = "Min Curvature Window";
var MAX_CURVATURE_WINDOW = "Max Curvature Window";
var MINIMUM_BRANCH_LENGTH = "Minimum Branch Length";
var MAXIMUM_DISPLAY_HDM = "Maximum Display HDM";
//var GAP_ANALYSIS = "GapAnalysis";
var MINIMUM_GAP_DIAMETER = "Minimum Gap Diameter";
var DELIM = ",";
var EOL = "\n";
var PARAM_FILE_NAME = "parameters.txt";
var HDM_RESULTS_FILENAME = "_ResultsHDM.csv";
var ANAMORF_RESULTS_FILENAME = "results.csv";
var TWOMBLI_RESULTS_FILENAME = "Twombli_Results";

// global variables with default values
var contrastSaturation = 0.35;
var minLineWidth = 5;
var maxLineWidth = 5;
var minCurvatureWindow = 40;
var maxCurvatureWindow = 40;
var curvatureWindowStep = 10;
var minimumBranchLength = 10;
var maximumDisplayHDM = 200;
var gapAnalysis = true;
var minimumGapDiameter = 0;

var minLineWidthTest = 5;
var maxLineWidthTest = 20;

var contrastHigh = 120.0;
var contrastLow = 0.0;
var outputMasks = "";

var darkline;

/*
 ------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
	1. PRE CHECKS
-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
*/

print("Maximimise the log then click OK"); // ask user to maximimse log
waitForUser("Maximimise the log then click OK");
if (isOpen("Log")) { 				// reposition in top left corner
     selectWindow("Log"); 
     setLocation(0, 0); 
  } 

print("\n Prechecks...");
happyWithValues=false; // will stay in this while loop choosing parameter values until happyWithValues==true
if(getBoolean("Do you have a pre-existing parameter file you wish to load?")){ // if user has already decided parameter values in previous runs
	print("Select pre-existing parameter file");
	loadParameterFile();
	happyWithValues = true;
	if(minimumGapDiameter != 0){
		gapAnalysis=true;
	}
	darkline = getBoolean("Are the matrix fibres dark on a light background?");
}

wait(11);
print("\nStep 0"); 
print("Organise images into Eligible and Ineligible folders. See documentation for guidance");
	wait(11);
	
/*
	Resolution and removing dodgy samples
*/


while(happyWithValues==false)
{
	print("\nStep 1: Image resolution");
// all manual instructions for the user
	wait(11);
	print("Move any images of resolution lower than 1 pixel = 1 micron from the Eligible folder to the Ineligible folder. Can check this by clicking Image->Show info");
	wait(11);
	waitForUser("Once all images in Eligible folder have high enough resolution, click 'OK'");
	wait(11);
	
	print("\nStep 2: Image quality");
	wait(11);
	print("Make sure all images in Eligible folder are in focus and contain a significant proportion of matrix fibres. See Documentation Figure 2 for guidance ");
	wait(11);
	waitForUser("Once all images in Eligible folder are high enough quality, click 'OK'");
	wait(11);


	print("\nStep 3: File organization");
	wait(11);
	print("Have you organized the images correctly with three images from the Eligible folder copied in to the Test Set folder?");
	wait(11);
	waitForUser("Once images are correctly organised into Eligible, Ineligible and Test Set folders, click 'OK'");
	wait(11);

	print("\n Good \n You are now ready to choose analysis parameters ");
	wait(11);

	ans1 = getBoolean("Are you happy to proceed to the next step?"); // check with the user to next step. If not happy then programme exits.
	if(ans1==false)
	{
		exit();
	}
	
/*
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
	2.CHOOSING SENSIBLE PARAMETERS
-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
 -----------------------------------------------------------------------------------------------------------------------------
*/
print("Choosing sensible parameters...");

	
	//---------------------------------------------------------------------------------
	print("\nStep 4: Color balance");
	wait(11);
	
	happyTestFolders=false;
	while(happyTestFolders==false){
		print("Select Test Set Input folder (TestSetInput)");
		inputTestSet = getDirectory("Select Test Set Input folder (TestSetInput)"); // asks user to select input folder (interactive)
		print("Select where output Test Masks will be saved to (TestSetMasks)");
		outputTestMasks = getDirectory("Select where output Test Masks will be saved to (TestSetMasks)");
		print("Select where output images thresholded for high-density matrix (HDM)  will be saved to (TestSetHDM)");
		outputTestHDM = getDirectory("Select where output high-density matrix (HDM)  images will be saved to (TestSetHDM)");
	
		
		Dialog.create("Recap Folders");
		// User can override any values here
		Dialog.addString("inputTestSet:", inputTestSet,100);
		Dialog.addString("outputTestMasks:", outputTestMasks,100);
		Dialog.addString("outputTestHDM:", outputTestHDM,100);
		Dialog.show();
	
		happyTestFolders=getBoolean("Are these test folders correct? Click no to select different folders");
	}
	
	inputTestSet = Dialog.getString();
	outputTestMasks = Dialog.getString();
	outputTestHDM = Dialog.getString();
	
	IJ.redirectErrorMessages(); // does not abort if the folder contains an image that imagej can't open
	
	// opening as 8-bit images
	wait(11);
	print("Converting all test images to 8-bit...");
	run("Close All");
	IJ.redirectErrorMessages();
	openFolder(inputTestSet);
	ids=newArray(nImages); 
	for (i=0;i<nImages;i++) { 
	    selectImage(i+1); 
	    ids[i]=getImageID;
	    run("8-bit");
	} 
	if(nImages==0){
		print("WARNING, no images in testSetInput");
	}
	wait(11);
	print("All test images now open are 8-bit images");

	//adjust contrast of image
	wait(11);
	print("Automatically adjusting color balance, saturating 35% of pixels");
	wait(11);
	for (i=0;i<nImages;i++) { 
	    selectImage(i+1); 
	    ids[i]=getImageID;
	    run("Enhance Contrast", "saturated=0.35");
	}

	//check if user is happy with contrast
	waitForUser("Have you looked at the test set images?");
	happyContrast = getBoolean("Does contrast of the images look sharp enough? (See Documentation Figure 3)");
	
	while(happyContrast==false)
	{
		testSaturationValue = getNumber("Enter a saturation value between 0 and 1 ", 0.35); 
		wait(11);

		for (i=0;i<nImages;i++) { 
			    selectImage(i+1); 
			    ids[i]=getImageID;
			    run("Enhance Contrast", "saturated=" + testSaturationValue);
			}
		
		contrastSaturation=testSaturationValue;
		waitForUser("Have you looked at the test set images?");
		happyContrast = getBoolean("Does contrast of the images now look sharp enough?");
	}
	
	// get user to choose line width for ridge detection
	wait(11);
	print("\n Step 5: Choosing line width(s) for ridge detection and minimum branch length. See documentation page 9");
	wait(11);
	darkline = getBoolean("Are the matrix fibres dark on a light background? (Select 'No' if they are light fibres on a dark bacground)"); //thresholding different depending if image is on light or dark background
	wait(11);
	wait(11);
	happyLineWidth=false;
	while(happyLineWidth==false){
		wait(11);
		print("Exploratory line width analysis");
		minLineWidthTest = getNumber("Enter a proposed min line width (try a multiple of 5)", minLineWidthTest); // ask user to input 
		maxLineWidthTest = getNumber("Enter a proposed max line width (try a multiple of 5)", maxLineWidthTest); // ask user to input 
		if(minLineWidthTest<=1){
			getNumber("Proposed min line width is too small, please choose a larger value", minLineWidthTest); // ask user to input 
		}

		runTestRidgeDetection(inputTestSet,outputTestMasks,5);
		print("\n Take a look at the output masks with different linewidths and the TestingMultipleLineWidths.csv file to choose an appropriate line width(s)");
		waitForUser("\n Take a look at the output masks with different linewidths and the TestingMultipleLineWidths.csv file to choose an appropriate line width(s)"); 
//
//		run("Close All");
//		IJ.redirectErrorMessages();
//		openFolder(inputTestSet);
//
//		for (i=0;i<nImages;i++) { 
//		    selectImage(i+1); 
//		    ids[i]=getImageID;
//		    run("Enhance Contrast", "saturated=" + contrastSaturation);
//		    run("8-bit");
//		}

		
//		wait(11);
//		print("\n If you are happy to use a single line width, set minLineWidth and maxLineWidth to same value");
//
		print("\n If you are happy to use a single line width (advisable), set minLineWidth and maxLineWidth to same value. \n Setting minLineWidth and maxLineWidth to different values will identify fibres of different thicknesses (but may take longer)");
		wait(11);

		waitForUser("\n If you are happy to use a single line width (advisable), set minLineWidth and maxLineWidth to same value. \n Setting minLineWidth and maxLineWidth to different values will identify fibres of different thicknesses (but may take longer)"); 
		minLineWidth = getNumber("Enter a proposed min line width ", minLineWidthTest); // ask user to input 
		maxLineWidth = getNumber("Enter a proposed max line width ", minLineWidthTest); // ask user to input 
		print("Choosing minimum branch length");
		print("Now computing masks for several different minimum branch lengths...");
		tryMinimumBranchLength(inputTestSet,outputTestMasks);
		print("Done. Take a look at the output masks with different MIN_BRANCH_LENGTH (Documentation Fig 4)");
		waitForUser("\n Take a look at the output masks with different MIN_BRANCH_LENGTH (Documentation Fig 4)"); 
		minimumBranchLength = getNumber("Enter a proposed min branch length ", minimumBranchLength); // ask user to input 
		
		wait(11);
		print("Computing masks for the specified values of min/max line width and min branch length...");
		openFolder(inputTestSet);

		for (i=0;i<nImages;i++) { 
		    selectImage(i+1); 
		    ids[i]=getImageID;
		    run("Enhance Contrast", "saturated=" + contrastSaturation);
		    run("8-bit");
		}
		
		// doing ridge detection
		titles = getList("image.titles");
		for(j=0; j<titles.length;j++){
			selectWindow(titles[j]);
			runMultiScaleRidgeDetection();
		    run("Out [-]"); 
		} 

		openFolder(inputTestSet);
		
		// gives user chance to run ridge detection again with different line width
		print("Once you have compared the masks with the images, click OK"); 
		waitForUser("Once you have compared the masks with the images, click OK"); 
		happyLineWidth=getBoolean("Are you happy with the masks produced with this line width(s) and minimum branch length? (Click no if you want to repeat this step)");
	}
	wait(11);

	run("Close All");
	print("\n Generating masks for test images...");
//	processFolderRidgeDetection(inputTestSet,outputTestMasks); // generate masks for testSet
//	run("Close All");
	wait(11);
	openFolderSpecific(outputTestMasks);


	wait(11);
	print("\n Step 6: Choosing curvature window(s). (See Documentation Figures 5 & 6)");
	wait(11);
	
	happyCurvature=false;
	while(happyCurvature==false){
		print("For each open mask, use the 'straight line' tool to choose a reasonable");
		print("curvature window. Try measuring the length of approximately straight lines ");
		print("on the mask without sharp turns or branches (see Figure 5 in documentation).");
		wait(11);
		 
		wait(11);
		waitForUser("Decide curvature window(s), then click 'OK'"); 
		print("Decide curvature window(s), then click 'OK'");

		waitForUser("\n If you are happy to use a single curvature window, set minCurvatureWindow and maxCurvatureWindow to same value. \n Setting minCurvatureWindow and maxCurvatureWindow to different values will provide more detailed curvature output (but may take longer)"); 
		print("\n If you are happy to use a single curvature window, set minCurvatureWindow and maxCurvatureWindow to same value. \n Setting minCurvatureWindow and maxCurvatureWindow to different values will provide more detailed curvature output (but may take longer)"); 
		wait(11);
		minCurvatureWindow = getNumber("Min curvature window", minCurvatureWindow); 
		maxCurvatureWindow = getNumber("Max curvature window", maxCurvatureWindow); 

		happyCurvature = getBoolean("Are you happy to move on? Click no if you want to choose different curvature windows)");
	}

	/*
	Optional gap analysis
	*/
	print("\nStep 7: Optional gap analysis");
	wait(11);
    gapAnalysis=getBoolean("Do you want to include gap analysis? (See Documentation Figure 8)");
	if(gapAnalysis==true)
	{
		wait(11);
		print("For each open mask, use the 'straight line' tool to decide the minimum diameter");
		print("for gaps you want to measure. The smaller the gaps, the longer the analysis ");
		print("will take.");
		wait(11);

		print("Once you have decided on the minimum gap diameter, click OK and enter the value when prompted");
		wait(11);
		waitForUser("Decide minimum gap diameter, then click 'OK'"); 

		w = getWidth();
		h = getHeight();
		l= floor((w+h)/60);

		minimumGapDiameter = getNumber("minimum gap diameter", l);
	} else{
		minimumGapDiameter = 0;
	}
	
	/*
	Threshold value for HDM
	*/
	happyWithHDM=false;
	while(happyWithHDM==false){
	print("\nStep 8: Choosing threshold value for HDM.  (See Documentation Figure 7)");
	wait(11);
	
	print("Reopening and adjusting contrast of all testSet images...");
		run("Close All");
		IJ.redirectErrorMessages();
		openFolder(inputTestSet);
		ids=newArray(nImages); 
		for (i=0;i<nImages;i++) { 
		    selectImage(i+1); 
		    ids[i]=getImageID;
		    run("Enhance Contrast", "saturated=" + contrastSaturation);
		    run("8-bit");  
		    if(darkline==false) // so that HDM will be computed against dark background
		    {
				run("Invert");
			}
		} 
	
	print("\n Adjust maximum value in brightness and contrast window (by sliding second bar) to remove anything that is not matrix");
	run("Brightness/Contrast...");
	print("Click 'set' to see maximum display values for each test image");
	wait(11);
	print("Once you have decided maximum display values click OK and enter this value when prompted");
	wait(11);
	waitForUser("Choose maximum display values (by sliding the second bar in the B&C box) to filter out background, then click 'OK'"); 
	wait(11);
	print("Enter maximum display value");
	maximumDisplayHDM = getNumber("maximum display HDM", 200); 
	wait(11);

	run("Close All");
	IJ.redirectErrorMessages();
	processFolderHDM(inputTestSet,outputTestHDM); // process image for computing HDM (ie thresholding out fainter fibres and background).
	run("Close All");

	openFolder(outputTestHDM);
	print("\n You have thresholded your images to compute high-density matrix (HDM)");
	waitForUser("Once you have looked at these images, click OK"); 
	print("\n Are these images mostly black (background) with some light pixels (high density matrix)? ");
	happyWithHDM = getBoolean("Are these images mostly black (background) with some light areas (high density matrix)? Click no to repeat this step");
	}
	run("Close All");
	
	 /*
		Conclusion: recapping chosen parameter values
	 */
	print("\n Good \n You have now chosen all necessary parameters to generate matrix information for your data");
	wait(11);
	print("\nStep 9: recapping chosen parameters");
	wait(11);
	print("\nDo these values seem reasonable? Do these masks and HDM images (in TestMasks and TestHDM folders) look good?");
	wait(11);
	
	Dialog.create("Recap values");
	// User can override any values here
	Dialog.addNumber("contrastSaturation:", contrastSaturation);
	Dialog.addNumber("minlineWidth:", minLineWidth);
	Dialog.addNumber("maxlineWidth:", maxLineWidth);
	Dialog.addNumber("minCurvatureWindow:", minCurvatureWindow);
	Dialog.addNumber("maxCurvatureWindow:", maxCurvatureWindow);
	Dialog.addNumber("minimumBranchLength:", minimumBranchLength);
	Dialog.addNumber("maximumDisplayHDM:", maximumDisplayHDM);
	if(gapAnalysis==true){
		Dialog.addNumber("minimumGapDiameter:", minimumGapDiameter);
	}
	Dialog.show();
	
	contrastSaturation = Dialog.getNumber();
	minLineWidth = Dialog.getNumber();
	maxLineWidth = Dialog.getNumber();
	minCurvatureWindow = Dialog.getNumber();
	maxCurvatureWindow = Dialog.getNumber();
	minimumBranchLength = Dialog.getNumber();
	maximumDisplayHDM = Dialog.getNumber();
	if(gapAnalysis==true){
		minimumGapDiameter = Dialog.getNumber();
	} 
	
	happyWithValues = getBoolean("Are you happy with the parameter values? Click 'No' to start over");
	if(happyWithValues==false)
	{
		print("Exiting macro. Go back to start of prechecks to choose parameter values again");
		wait(11);
	}
else{
		saveParameterFile(); // write the chosen parameter files to a parameter file, so next time user can skip previous steps
	}
}
print("End of pre-checks");
wait(11);

close("*");
//close everything.

/*
 ------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
	3. RIDGE DETECTION
-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
 -----------------------------------------------------------------------------------------------------------------------------
 */
 
// computes ridge detection (to make masks) on all files in eligible folder
print("\nStep 10: Choosing directories and files");
wait(11);

happyRealFolders=false;
while(happyRealFolders==false){
	print("Select 'Eligible' folder as input directory");
	inputEligible = getDirectory("Select 'Eligible' folder as input directory");
	//inputRaw = inputEligible; // for coming back to with computing HDM
	print("Select output directory 'Masks' where masks will be saved");
	outputMasks = getDirectory("Choose an output directory 'Masks' where masks will be saved");
	
	print("Choose an output directory for HDM");
	outputHDM = getDirectory("Choose an output directory for HDM");
	countFiles(outputHDM);
	
	wait(11);
	print("Finally, choose file anamorfProperties.xml (in the programs folder)");
	anamorfProperties = File.openDialog("Choose file anamorfProperties.xml (in the programs folder)");
	
	Dialog.create("Recap Folders");
	// User can override any values here
	Dialog.addString("inputEligible:", inputEligible,100);
	Dialog.addString("outputMasks:", outputMasks,100);
	Dialog.addString("outputHDM:", outputHDM,100);
	Dialog.addString("anamorfProperties:", anamorfProperties,100);
	Dialog.show();

	happyRealFolders=getBoolean("Are these  folders correct? These folders should NOT be test folders. Click no to select different folders");
}

inputEligible = Dialog.getString();
outputMasks = Dialog.getString();
outputHDM = Dialog.getString();
anamorfProperties = Dialog.getString();



print("\nGood, you have chosen all necessary files. Twombli is ready to process all images");
wait(11);

print("\nStep 11: ridge detection");
wait(11);


IJ.redirectErrorMessages();
processFolderRidgeDetection(inputEligible,outputMasks);


print("FINISHED deriving masks!");
close("*");

/*
 ------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
	4. ANAMORF
-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
*/

// computes Anamorf (where most of the metrics are derived) on all eligible files
inputAnamorf = outputMasks;
wait(11);
print("\nStep 12: extracting parameters with Anamorf");


run("AnaMorf Macro Extensions");
Ext.initialiseAnaMorf(inputAnamorf,anamorfProperties);
// anamorfProperties is a .xml file - for now just leave this. Might be able to remove in future

Ext.setAnaMorfFileType("PNG");
// don't worry about this - the masks generated are of png type, so this should be left alone
Ext.setAnaMorfCurvatureWindow(minCurvatureWindow);
Ext.setAnaMorfMinBranchLength(minimumBranchLength);
Ext.runAnaMorf();

for(c = minCurvatureWindow + curvatureWindowStep; c <= maxCurvatureWindow; c += curvatureWindowStep){
	Ext.resetParameters();
	Ext.setAnaMorfCurvatureWindow(c);
	Ext.runAnaMorf();	
}

wait(11);
print("HERE exiting anamorf");

wait(11);
print("Now computing alignment");
alignmentVec=newArray(0);
alignmentVec = processFolderAlignment(outputMasks);	
var dimensionsVec = processFolderDimensions(outputMasks);
var alignmentVecOrder = getAlignmentVecOrder(outputMasks);
print("Finished computing alignment");
close("*");

/*
 ------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
	4. HDM
-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
*/
// Computes HDM on all Eligible images
wait(11);
print("\nStep 13: Computing HDM");
run("Clear Results");
inputHDM = inputEligible;

IJ.redirectErrorMessages();
processFolderHDM(inputHDM,outputHDM);

// The code for computing HDM is called QBS = QuantBlackSpace
setBatchMode(true);
pathToQBS = searchForFile(getDirectory("imagej"), "", "Quant_Black_Space.ijm");
runMacro(pathToQBS, outputHDM);
saveAs("Results", outputHDM + File.separator + HDM_RESULTS_FILENAME);
close("Results");

setBatchMode(false);
print("FINISHED HDM!");
wait(1000);


/*
 ------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
	5. Gap analysis
-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
*/

print("gap analysis = ", gapAnalysis);
if(gapAnalysis==true)
{
	wait(11);
	print("\nOptional Step 14: Computing Gap analysis");
	print("minimumGapDiameter = ",minimumGapDiameter);

	File.makeDirectory(outputMasks+"/GapAnalysis");
	
	processFolderGap(outputMasks);
	
	if (isOpen("Results")) {
			 selectWindow("Results");
			 run("Close");}
	
	print("FINISHED GAP ANALYSIS!");
	wait(11);
	print("Gap analysis can be found in output masks folder");
	print("containing masks with gaps shown, and a summary txt file");
}
print("Just before tidyResults");
tidyResults(outputHDM, inputAnamorf, inputEligible, alignmentVec);
print("FINISHED EVERYTHING!");

/*
 ------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
	5. LIST OF FUNCTIONS
-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------
*/
/*
FUNCTION OVERVIEW (indentations mean functions inside other functions)

openFolder(input)
	openFile (input, file)
runTestRidgeDetection(inputDir,outputDir)
tryMinimumBranchLength(inputDir,outputDir)
processFolderRidgeDetection(input, output)
	processFileRidgeDetection (input, output, file)
		runMultiScaleRidgeDetection()
			printResult(lineWidth)
		calcSigma()
		calcLowerThresh(estimatedSigma)
		calcUpperThresh(estimatedSigma)
countFiles(dir)
processFolderHDM(inputHDM, outputHDM)
	processFileHDM(inputHDM, outputHDM, file)
searchForFile(input, targetPath, target)
saveParameterFile()
loadParameterFile()
processFolderGap(input)
	processFileGap(input)
		append(arr, value) 
		percentile(arr,p)
		closeROI()
	processFolderAlignment()
		processFileAlignment()
tidyResults()
*/

// function to open all files in a folder
function openFolder(input) { 
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
{
			openTestSetFolder(input + File.separator + list[i]);
		} else {
			openFile(input, list[i]);
		}
	}
}

//function openFolderSpecific(input) { 
//	list = getFileList(input);
//	list = Array.sort(list);
//	suffix1 = "_" + minLineWidth + ".png";
//	suffix2 = "_" + maxLineWidth + ".png";
//	for (i = 0; i < list.length; i++) {
//		if(File.isDirectory(input + File.separator + list[i]))
//		{
//			openTestSetFolder(input + File.separator + list[i]);
//		} else {
//			if(endsWith(list[i], suffix1)){
//				openFile(input, list[i]);
//			}
//			if(minLineWidth!=maxLineWidth){
//				if(endsWith(list[i], suffix2)){
//				openFile(input, list[i]);
//				}
//			}
//		}
//	}
//}

function openFolderSpecific(input) { 
	list = getFileList(input);
	list = Array.sort(list);
	suffix1 = "LENGTH_" + minimumBranchLength + ".png";
		for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
		{
			openTestSetFolder(input + File.separator + list[i]);
		} else {
			if(endsWith(list[i], suffix1)){
				openFile(input, list[i]);
			}
			}
		}
	}




function openFile(input, file) {
	print("opening file " + input + File.separator + file);
	open(input + File.separator + file);
	run("Out [-]"); // zoom out
}	

function runTestRidgeDetection(inputDir,outputDir,lineWidthStep){

fileList = getFileList(inputDir);

setBatchMode(true);

run("Clear Results");

for (i = 0; i < fileList.length; i++) {

	open(inputDir + File.separator + fileList[i]);
    run("Enhance Contrast", "saturated=" + contrastSaturation);
    run("8-bit");

	
	setResult("Image Title", nResults, fileList[i]);
	input = getTitle();
	sigma = calcSigma(minLineWidthTest-1);
	lowerThresh = calcLowerThresh(minLineWidthTest-1, sigma);
	upperThresh = calcUpperThresh(minLineWidthTest-1, sigma);
	if(darkline){
			run("Ridge Detection", "line_width=" + minLineWidthTest-1 + " high_contrast=" + contrastHigh + " low_contrast=" + contrastLow + " darkline extend_line make_binary method_for_overlap_resolution=NONE sigma=" + sigma + " lower_threshold=" + lowerThresh + " upper_threshold=" + upperThresh + " minimum_line_length=" + minimumBranchLength + " maximum=0");
		} else{
			run("Ridge Detection", "line_width=" + minLineWidthTest-1 + " high_contrast=" + contrastHigh + " low_contrast=" + contrastLow + " extend_line make_binary method_for_overlap_resolution=NONE sigma=" + sigma + " lower_threshold=" + lowerThresh + " upper_threshold=" + upperThresh + " minimum_line_length=" + minimumBranchLength + " maximum=0");
		}
	rename("lw_" + minLineWidthTest-1);
	result = getTitle();
	
	lw = minLineWidthTest;
	while(lw<=maxLineWidthTest){
		sigma = calcSigma(lw);
		lowerThresh = calcLowerThresh(lw, sigma);
		upperThresh = calcUpperThresh(lw, sigma);
		selectWindow(input);
		print("Running ridge detection for line width " + lw + " on " + fileList[i]);
		if(darkline){
			run("Ridge Detection", "line_width=" + lw + " high_contrast=" + contrastHigh + " low_contrast=" + contrastLow + " darkline extend_line make_binary method_for_overlap_resolution=NONE sigma=" + sigma + " lower_threshold=" + lowerThresh + " upper_threshold=" + upperThresh + " minimum_line_length=" + minimumBranchLength + " maximum=0");
		} else{
			run("Ridge Detection", "line_width=" + lw + " high_contrast=" + contrastHigh + " low_contrast=" + contrastLow + " extend_line make_binary method_for_overlap_resolution=NONE sigma=" + sigma + " lower_threshold=" + lowerThresh + " upper_threshold=" + upperThresh + " minimum_line_length=" + minimumBranchLength + " maximum=0");
		}
		rename("lw_" + lw);
		this_result = getTitle();
		printResult(lw);
		imageCalculator("OR create", result, this_result);
		rename("Composite_" + lw);
		temp = result;
		result = getTitle();
		close(temp);
		selectWindow(this_result);
		saveAs("PNG", outputDir + File.separator + fileList[i] + "_mask_" + lw);
		close();
		lw = lw + lineWidthStep;
	}
	
//	saveAs("PNG", outputDir + File.separator + fileList[i] + "_composite_mask");
	close("*");

}

saveAs("Results", outputDir + File.separator + "TestingMultipleLineWidths.csv");
close("Results");

setBatchMode(false);

print("Done");

}

function tryMinimumBranchLength(inputDir,outputDir){

fileList = getFileList(inputDir);

setBatchMode(true);

//run("Clear Results");
mbl = 5;
while(mbl<=15){
	for (i = 0; i < fileList.length; i++) {
	
		open(inputDir + File.separator + fileList[i]);
	    run("Enhance Contrast", "saturated=" + contrastSaturation);
	    run("8-bit");
		
		input = getTitle();
		lw = minLineWidth;
		sigma = calcSigma(lw);
		lowerThresh = calcLowerThresh(lw, sigma);
		upperThresh = calcUpperThresh(lw, sigma);
		selectWindow(input);
		//print("Running ridge detection for minimum branch length " + mbl + " on " + fileList[i]);
		if(darkline){
			run("Ridge Detection", "line_width=" + lw + " high_contrast=" + contrastHigh + " low_contrast=" + contrastLow + " darkline extend_line make_binary method_for_overlap_resolution=NONE sigma=" + sigma + " lower_threshold=" + lowerThresh + " upper_threshold=" + upperThresh + " minimum_line_length=" + mbl + " maximum=0");
		} else{
			run("Ridge Detection", "line_width=" + lw + " high_contrast=" + contrastHigh + " low_contrast=" + contrastLow + " extend_line make_binary method_for_overlap_resolution=NONE sigma=" + sigma + " lower_threshold=" + lowerThresh + " upper_threshold=" + upperThresh + " minimum_line_length=" + mbl + " maximum=0");
		}

		saveAs("PNG", outputDir + File.separator + fileList[i] + "_MIN_BRANCH_LENGTH_" + mbl);
		close("*");
		}
	mbl = mbl + 5;
	}	
	close("*");

	setBatchMode(false);	
}
	// function to scan folders/subfolders/files to find files with correct suffix
function processFolderRidgeDetection(input,output) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
{
			processFolderRidgeDetection(input + File.separator + list[i], output);
		//if(endsWith(list[i], suffix))
		} else {
			processFileRidgeDetection(input, output, list[i]);
		}
	}
}

function processFileRidgeDetection(input, output, file) {
	// Do the processing here by adding your own code.
	// Leave the print statements until things work, then remove them.
	setBatchMode(true);
	open(input + File.separator + file);
	run("Out [-]");
	print("Processing: " + input + File.separator + file);
	
	run("Enhance Contrast", "saturated=0.35");
	
	run("8-bit");

	runMultiScaleRidgeDetection();

	// Invert LUT
	getLut(reds, greens, blues);
	for (i=0; i<reds.length; i++) {
	    reds[i] = 255-reds[i];
	    greens[i] = 255-greens[i];
	    blues[i] = 255-blues[i];
	}
	
	setLut(reds, greens, blues);
	run("Invert");

	saveAs("PNG", output + File.separator + file);
	
	IJ.redirectErrorMessages() ;
	titles = getList("image.titles");


	for(j=0; j<titles.length;j++){
		print("titles[j] = ", titles[j]);
		selectWindow(titles[j]);
		close();
	}
	
	print("Saving to: " + output);
	setBatchMode(false);
}

function runMultiScaleRidgeDetection(){
	print("Running Ridge detection");
	input = getTitle();
	sigma = calcSigma(minLineWidth);
	lowerThresh = calcLowerThresh(minLineWidth, sigma);
	upperThresh = calcUpperThresh(minLineWidth, sigma);
	if(darkline){
			run("Ridge Detection", "line_width=" + minLineWidth + " high_contrast=" + contrastHigh + " low_contrast=" + contrastLow + " darkline extend_line make_binary method_for_overlap_resolution=NONE sigma=" + sigma + " lower_threshold=" + lowerThresh + " upper_threshold=" + upperThresh + " minimum_line_length=" + minimumBranchLength + " maximum=0");
		} else{
			run("Ridge Detection", "line_width=" + minLineWidth + " high_contrast=" + contrastHigh + " low_contrast=" + contrastLow + " extend_line make_binary method_for_overlap_resolution=NONE sigma=" + sigma + " lower_threshold=" + lowerThresh + " upper_threshold=" + upperThresh + " minimum_line_length=" + minimumBranchLength + " maximum=0");
		}
	result = getTitle();
	
	lw = minLineWidth;
	while(lw<=maxLineWidth){
		sigma = calcSigma(lw);
		lowerThresh = calcLowerThresh(lw, sigma);
		upperThresh = calcUpperThresh(lw, sigma);
		selectWindow(input);
		if(darkline){
			run("Ridge Detection", "line_width=" + lw + " high_contrast=" + contrastHigh + " low_contrast=" + contrastLow + " darkline extend_line make_binary method_for_overlap_resolution=NONE sigma=" + sigma + " lower_threshold=" + lowerThresh + " upper_threshold=" + upperThresh + " minimum_line_length=" + minimumBranchLength + " maximum=0");
		} else{
			run("Ridge Detection", "line_width=" + lw + " high_contrast=" + contrastHigh + " low_contrast=" + contrastLow + " extend_line make_binary method_for_overlap_resolution=NONE sigma=" + sigma + " lower_threshold=" + lowerThresh + " upper_threshold=" + upperThresh + " minimum_line_length=" + minimumBranchLength + " maximum=0");
		}
		this_result = getTitle();
		imageCalculator("OR create", result, this_result);
		temp = result;
		result = getTitle();
		close(temp);
		close(this_result);
		lw = lw + 1;
	}
}

function printResult(lineWidth){
	getHistogram(values, counts, 256);
	setResult("Line Width " + lineWidth, nResults-1, counts[255]);
}

// called before processFolderHDM - if folder is not empty, macro might not work.
function countFiles(dir) {
      count=0;
      list = getFileList(dir);
      for (i=0; i<list.length; i++) {
          if (endsWith(list[i], "/"))
              countFiles(""+dir+list[i]);
          else
              count++;
      }
      if(count!=0)
      {
			print("\nWarning! The output HDM folder you have chosen is not empty so macro will not run. Empty this folder before proceeding.");
			waitForUser("When you have emptied the output HDM folder, click OK to proceed");
      }
  }

// function to scan folders/subfolders/files to find files with correct suffix
function processFolderHDM(inputHDM,outputHDM) {
	list = getFileList(inputHDM);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(inputHDM + File.separator + list[i])){
			processFolderHDM(inputHDM + File.separator + list[i], outputHDM);
		}
		processFileHDM(inputHDM, outputHDM, list[i]);
	}
}

function processFileHDM(inputHDM, outputHDM, file) {
	// Do the processing here by adding your own code.
	// Leave the print statements until things work, then remove them.

	setBatchMode(true);
	open(inputHDM + File.separator + file);
	run("Out [-]");
	run("8-bit");
	if(darkline==false){
		run("Invert");
	}
	setMinAndMax(0, maximumDisplayHDM);
	run("Apply LUT");
	run("Invert");
	run("Enhance Contrast", "saturated=" + contrastSaturation);
	saveAs("PNG", outputHDM + File.separator + file);
	titles = getList("image.titles");

	for(j=0; j<titles.length;j++){
		print("titles[j] = ", titles[j]);
		selectWindow(titles[j]);
		close();
	}
	setBatchMode(false);
}

function searchForFile(input, targetPath, target) {
      list = getFileList(input);
      list = Array.sort(list);
      for (i = 0; i < list.length; i++) {
            if(File.isDirectory(input + File.separator + list[i]))
                  targetPath = searchForFile(input + File.separator + list[i], targetPath, target);
            if(startsWith(list[i], target)){
                  return input + File.separator + list[i];
            }
      }
      return targetPath;
}

function saveParameterFile(){
	print("Save the parameter file somewhere sensible so you can use these parameters again");
	parameterFilePath = getDirectory("Specify location for parameter file") + File.separator + PARAM_FILE_NAME;
	print("Saving parameter file in " + parameterFilePath);
	if(File.exists(parameterFilePath)){
		File.delete(parameterFilePath);
	}
	parameterFile = File.open(parameterFilePath);

	print(parameterFile, CONTRAST_SATURATION + DELIM + contrastSaturation + EOL);
	print(parameterFile, MIN_LINE_WIDTH + DELIM + minLineWidth + EOL);
	print(parameterFile, MAX_LINE_WIDTH + DELIM + maxLineWidth + EOL);
	print(parameterFile, MIN_CURVATURE_WINDOW + DELIM + minCurvatureWindow + EOL);
	print(parameterFile, MAX_CURVATURE_WINDOW + DELIM + maxCurvatureWindow + EOL);
	print(parameterFile, MINIMUM_BRANCH_LENGTH + DELIM + minimumBranchLength + EOL);
	print(parameterFile, MAXIMUM_DISPLAY_HDM + DELIM + maximumDisplayHDM + EOL);
	print(parameterFile, MINIMUM_GAP_DIAMETER + DELIM + minimumGapDiameter + EOL);

	File.close(parameterFile);
}


function loadParameterFile(){
	parameterFile = File.openDialog("Specify location of parameter file");
	parameterString = File.openAsString(parameterFile);

	lines = split(parameterString, EOL);

	nLines = lengthOf(lines);

	for (i = 0; i < nLines; i++) {
		words = split(lines[i], DELIM);
		if(startsWith(words[0], CONTRAST_SATURATION)){
			contrastSaturation = parseFloat(words[1]);
		} else if(startsWith(words[0], MIN_LINE_WIDTH)){
			minLineWidth = parseFloat(words[1]);
		} else if(startsWith(words[0], MAX_LINE_WIDTH)){
			maxLineWidth = parseFloat(words[1]);
		} else if(startsWith(words[0], MIN_CURVATURE_WINDOW)){
			minCurvatureWindow = parseFloat(words[1]);
		} else if(startsWith(words[0], MAX_CURVATURE_WINDOW)){
			maxCurvatureWindow = parseFloat(words[1]);
		} else if(startsWith(words[0], MINIMUM_BRANCH_LENGTH)){
			minimumBranchLength = parseFloat(words[1]);
		} else if(startsWith(words[0], MAXIMUM_DISPLAY_HDM)){
			maximumDisplayHDM = parseFloat(words[1]);
		} else if(startsWith(words[0], MINIMUM_GAP_DIAMETER)){
			minimumGapDiameter = parseFloat(words[1]);
		}
	}
}

// These functions are used to calculate thresholds in ridge detection
// Functions to calculate ridge detection parameters, taken from:
// https://github.com/thorstenwagner/ij-ridgedetection/blob/master/src/main/java/de/biomedical_imaging/ij/steger/Lines_.java

function calcSigma(lineWidth){
	return lineWidth / (2 * sqrt(3)) + 0.5;
}

function calcLowerThresh(lineWidth, estimatedSigma){
	clow=contrastLow;
	if(darkline){
		clow = 255 - contrastHigh;
	}
	return 0.17 * floor(abs(-2 * clow * (lineWidth / 2.0)
					/ (sqrt(2 * PI) * estimatedSigma * estimatedSigma * estimatedSigma)
					* exp(-((lineWidth / 2.0) * (lineWidth / 2.0)) / (2 * estimatedSigma * estimatedSigma))));
}

function calcUpperThresh(lineWidth, estimatedSigma){
	chigh = contrastHigh;
	if (darkline) {
		chigh = 255 - contrastLow;
	}
	return 0.17 * floor(abs(-2 * chigh * (lineWidth / 2.0)
					/ (sqrt(2 * PI) * estimatedSigma * estimatedSigma * estimatedSigma)
					* exp(-((lineWidth / 2.0) * (lineWidth / 2.0)) / (2 * estimatedSigma * estimatedSigma))));
}

function processFolderGap(input) {
	list = getFileList(input);
	list = Array.sort(list);
	gapAnalysisFile = File.open(input + "/GapAnalysis/GapAnalysisSummary.txt");
	print(gapAnalysisFile,  "filename mean sd percentile5 median percentile95");
	for (i = 0; i < list.length; i++) {
		if(endsWith(list[i],"png"))
		{
			processFileGap(input, list[i],gapAnalysisFile);
		}
	}
	File.close(gapAnalysisFile);
}

function processFileGap(input, file, gapAnalysisFile) {
	setBatchMode(true);
	
	print("Performing gap analysis on ", file);
	run("Clear Results");
	
	open(input + File.separator + file);
	
	w = getWidth();
	h = getHeight();
	makeRectangle(1, 1, w-2, h-2);
	run("Crop");
	run("Canvas Size...", "width="+w+" height="+h+" position=Center zero");
	
	run("Max Inscribed Circles", "minimum_disk=" + minimumGapDiameter + " minimum_similarity=0.50 closeness=5");
	
	nROIs = roiManager("count");
	
	run("Duplicate...", " ");
	run("RGB Color");
	setForegroundColor(255, 0, 0);
	
	for (i = 0; i < nROIs; i++) {
		roiManager("select", i);
		Roi.setStrokeWidth(3);
		roiManager("draw");
	}
	
	saveAs("png", input + "/GapAnalysis/"+file +"_GapImage.png");
	close();
	roiManager("Measure");
	
	if(nROIs>0)	{
		areaCol = newArray(0);
		for (a=0; a<nResults(); a++) {
			areaCol = Array.concat(areaCol,getResult("Area",a));
		}
		Array.getStatistics(areaCol, min, max, mean, sd);
		
		arr2 = Array.sort(areaCol);
		
		print(gapAnalysisFile,  file + " " + mean + " " + sd + " " + percentile(arr2,0.05) + " " + percentile(arr2,0.5) + " " + percentile(arr2,0.95));
		
		selectWindow("Results");
		saveAs("Results", input + "/GapAnalysis/IndividualGaps_"+file +".csv");
		
		run("Clear Results");
	}
	close("ROI Manager");
	close("*");
	setBatchMode(false);
}

function percentile(arr,p) { 
	// comes from https://stackoverflow.com/questions/2374640/how-do-i-calculate-percentiles-with-python-numpy
	n = arr.length;
	if(n==0)
	{
		q=-1
	}
	k = (n-1)*p;
	f = floor(k);
	c = -floor(-k); // There is no ceiling function in ijm
	if(f==c)
	{
		q = arr[k];
	}else {
		d0=arr[f] * (c-k);
		d1 = arr[c] * (k-f);
		q = d0+d1;
	}
	return q;
}

function processFolderAlignment(input) { // this should be outputMasks folder
	list = getFileList(input);
	list = Array.sort(list);
	list2 = newArray(0);
	anamorfIndex = 0;
	for (j = 0; j < list.length; j++) {
		if(startsWith(list[j], "AnaMorf")){
			anamorfIndex = j;
		} else {
			list2=Array.concat(list2,list[j]);
		}
	}

	alignmentVec = newArray(list2.length);

	for (i = 0; i < list2.length; i++) {
		processFileAlignment(input, list2[i], alignmentVec, i);
	}
	return alignmentVec;
}

function getAlignmentVecOrder(input) { // this should be outputMasks folder
	list = getFileList(input);
	list = Array.sort(list);
	list2 = newArray(0);
	anamorfIndex = 0;
	for (j = 0; j < list.length; j++) {
		if(startsWith(list[j], "AnaMorf")){
			anamorfIndex = j;
		} else {
			list2=Array.concat(list2,list[j]);
		}
	}
	return list2;
}


function processFileAlignment(input,  file, alignmentVec, i) {
	setBatchMode(true);
	open(input + File.separator + file);
	print("Performing alignment analysis on ", file);
	run("Out [-]");
	
	T=getTitle();
	run("OrientationJ Dominant Direction");
	IJ.renameResults("Dominant Direction of "+T,"Results");
	alignmentVec[i]=getResult("Coherency [%]",0);

	run("Clear Results");
	close("*");
	setBatchMode(false);
}

function processFolderDimensions(input){
	list = getFileList(input);
	list = Array.sort(list);
	list2 = newArray(0);
	anamorfIndex = 0;
	for (j = 0; j < list.length; j++) {
		if(startsWith(list[j], "AnaMorf")){
			anamorfIndex = j;
		} else {
			list2=Array.concat(list2,list[j]);
		}
	}

	dimensionVec = newArray(list2.length);

	for (i = 0; i < list2.length; i++) {
		file = list2[i];
		setBatchMode(true);
		open(input + File.separator + file);
		h=getHeight();
		w=getWidth();
		dimensionVec[i]=h*w;
		close("*");
		setBatchMode(false);
	}
	return dimensionVec;
}

function tidyResults(outputHDM, inputAnamorf, inputEligible,alignmentVec){
	hdmResultsFile = outputHDM + File.separator + HDM_RESULTS_FILENAME;
	hdmResults = split(File.openAsString(hdmResultsFile), "\n");
	anaMorfFiles = getFileList(inputAnamorf);
	anaMorfFolderIndex = -1;
	
	for(i=0; i < anaMorfFiles.length; i++){
		if(checkIsAnaMorf(inputAnamorf, anaMorfFiles[i])){
			anaMorfFolderIndex = i;
			break;
		}
	}
	if(anaMorfFolderIndex > -1){
		anaMorfResults = newArray(0);
		for(j=0; j < anaMorfFiles.length; j++){
			if(checkIsAnaMorf(inputAnamorf, anaMorfFiles[j])){
				anaMorfResultsFile = inputAnamorf + File.separator + anaMorfFiles[j] + File.separator + ANAMORF_RESULTS_FILENAME;
				currentAnaMorfResults = split(File.openAsString(anaMorfResultsFile), "\n");
				if(anaMorfResults.length < 1){
					anaMorfResults = currentAnaMorfResults;
				} else{
					for(k=0; k<anaMorfResults.length;k++){
						anaMorfLine = split(currentAnaMorfResults[k], ",");
						anaMorfResults[k] = anaMorfResults[k] + "," + anaMorfLine[1];
					}
				}
			}
		}
		baseOutputFilepath = File.getParent(outputHDM) + File.separator + TWOMBLI_RESULTS_FILENAME;
		outputFilepath = baseOutputFilepath + ".csv";

		count = 1;
		while(File.exists(outputFilepath)){
			outputFilepath = baseOutputFilepath + "_" + count + ".csv";
			count++;
		}
		
		twombliResultsFile = File.open(outputFilepath);
		for(i = 0; i < anaMorfResults.length; i++){
			hdmIndex = i;
			if(i==1){
				i++;
			}
			if(i==0){
				hdm = "% High Density Matrix";
				alignment = "Alignment";
				dimension = "TotalImageArea";
			} else {
				anaMorfLine = split(anaMorfResults[i], ",");
				hdmIndex =  matchHDMResult(anaMorfLine[0], hdmResults);

				hdmLine = split(hdmResults[hdmIndex], ",");
				hdm = hdmLine[hdmLine.length - 1];
				hdm = 1-hdm;

				alignmentIndex = matchAlignmentResult(anaMorfLine[0]);
				alignment = alignmentVec[alignmentIndex];
				dimension = dimensionsVec[alignmentIndex];
			}

			
			line = anaMorfResults[i] + "," + hdm + "," + alignment + "," + dimension;
			print(twombliResultsFile, line);
		}
		File.close(twombliResultsFile);
	}
}

function checkIsAnaMorf(inputDir, inputFile){
	if(File.isDirectory(inputDir + File.separator + inputFile) && startsWith(inputFile, "AnaMorf")){
		return true;
	} else {
		return false;
	}
}

function matchHDMResult(imageName, hdmResults){
	for(i = 0; i < hdmResults.length; i++){
		line = hdmResults[i];
		splitLine = split(line, ",");
		if(startsWith(imageName, splitLine[1])){
			return i;
		}
	}
	return -1;
}

function matchAlignmentResult(imageName){
	for(i = 0; i < alignmentVecOrder.length; i++){
		if(startsWith(imageName, alignmentVecOrder[i])){
			return i;
		}
	}
	return -1;
}

