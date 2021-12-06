/*
 * written by Bettina Schmerl bettina.schmerl@charite.de
 * 
 * FiJi/ImageJ macro for punctae quantification and co-localisation analysis of multichannel confocal images
 * Ch1 = MAP2
 * Ch2 = MPP2
 * Ch3 = GABA(A)R subunits
 * Ch4 = Homer1
 * 
 * See related publication for experimental details
 * 
 * macro demands install of the "Measure Skeleton Length Tool" by Volker Baecker at Montpellier RIO Imaging (www.mri.cnrs.fr)
 * 
 */



dir=getDirectory("image");
imagename = getTitle();
Datum = "_20211206"; //info for results file name
Diameter = "1.0_microns"; //info for results file name
dia =  0.5; //provide expected spine radius to be analysed

files=getFileList(dir);
setOption("ExpandableArrays", true);

arrLengthDendrite = newArray();

//Homer
arrCountAllHomerp = newArray();
arrCountDenHomerp = newArray();
arrCountHomerpWithGABAAR  = newArray();
arrProzentGABAARposHomerOfDendritic = newArray();


//double + triple with MPP2
arrCountAllMPP2p = newArray();
arrCountDenMPP2p = newArray();
arrCountHomerpWithDenMPP2 = newArray();
arrProzentMPP2posDenHomerpOfDen = newArray();
arrCountHomerpTriPosHGM = newArray();
arrCountHomerpTriPosHMG = newArray();
arrProzentTriPosHomerHMGpOfDen = newArray();

//*******************


dotIndex = lastIndexOf(imagename, ".");
imageextension = substring(imagename, dotIndex, lengthOf(imagename));


//dialogue
batch=true;
Dialog.create("Enter Values");
	Dialog.addMessage("the following options are only required for batch analysis");
	Dialog.addCheckbox("Process all images from directory (Import must be selected)", batch);
	Dialog.addString("filetype image (e.g. .tif):", imageextension);
	

	Dialog.show();

    	batch = Dialog.getCheckbox();
    	imageextension=Dialog.getString();


//close previous results
if (isOpen("Results")) 
    {
     selectWindow("Results");
     run("Close");
    } 


//search for images in folder
hits=newArray();
for(j=0;j<files.length;j++)
	{
	dotIndex = lastIndexOf(files[j], "."); 
	thisextension = substring(files[j], dotIndex, lengthOf(files[j]));
	if (thisextension==imageextension)
		{hits=Array.concat(hits,files[j]);}
	} 
files=hits;
rounds=1;

if(batch==true){rounds=files.length;}

for(l=0;l<rounds;l++) 
	{
		
	print("---- Bild Nr. "+l+" ---- "+files[l]);//debug
	//close previous results
	if (isOpen("Results")) 
	    {
	     selectWindow("Results");
	     run("Close");
	    } 
	
	while (nImages>0) 
		{ 
		selectImage(nImages); 
		close(); 
		} 

						
	run("Collect Garbage");
	call("java.lang.System.gc");
			
	
	if(batch==true) {

		imagename=files[l];	
		run("Bio-Formats", "  open="+dir+imagename+" color_mode=Default view=Hyperstack stack_order=XYCZT");	

		//close previous results
		if (isOpen("Results")) 
		    {
		     selectWindow("Results");
		     run("Close");
		    } 
		nROIs = roiManager("count");
		if (nROIs > 0){
			roiManager("Deselect");
			roiManager("Delete");    
		}

		run("Set Measurements...", "area mean min integrated redirect=None decimal=3");
		

		selectWindow(imagename);
		run("Z Project...", "projection=[Max Intensity]");
		Stack.setDisplayMode("color");
		run("Duplicate...", "duplicate");
		rename("MAX_Duplicate1");
		run("Duplicate...", "duplicate");
		rename("MAX_Duplicate2");
		run("Duplicate...", "duplicate");
		rename("MAX_Duplicate3");
		selectWindow("MAX_Duplicate3");
		//binarize, skeletonize and measure dendrite length based in MAP2
		arrLengthDendrite = measureDendriteLength (l, arrLengthDendrite); 

		//----------------------------------------------
		//thresholding and GABA ROIs
			Stack.setChannel(3);
			run("Mean...", "radius=1.5 slice"); 
			run("Auto Threshold", "method=Moments white"); 
			run("Create Selection");
			roiManager("Add");
			roiManager("Select", 1);
			roiManager("Rename", "1_GABA_thresholded");
			roiManager("Deselect");
			//find GABAAR punctae by maxima
			run("Gaussian Blur...", "sigma=2 slice");
			run("Find Maxima...", "prominence=50 strict exclude output=[Point Selection]");
			roiManager("Add");
			roiManager("Select", 2);
			roiManager("Rename", "2_GABAAR_punctae");
			//create GABAAR Areas aka spines
			run("Enlarge...", "enlarge="+dia);
			roiManager("Add");
			roiManager("Select", 3);
			roiManager("Rename", "3_All_GABAAR_areas");
			roiManager("Deselect");
			
			//select GABA punctae within 2µm to dendrite
			roiManager("Select", newArray(0,2));
			roiManager("AND");
			roiManager("Add");
			roiManager("Select", 4);
			roiManager("Rename", "4_dendritic GABAARp");
			//create GABAAR punctae areas aka spines
			run("Enlarge...", "enlarge="+dia);
			roiManager("Add");
			roiManager("Select", 5);
			roiManager("Rename", "5_den_GABAAR_areas");
			roiManager("Deselect");
			
			run("Select None");

		//----------------------------------------------
		//thresholding and Homer1 ROIs
			Stack.setChannel(4);
			run("Mean...", "radius=1.5 slice");
			run("Auto Threshold", "method=Triangle white");
			run("Create Selection");
			roiManager("Add");
			roiManager("Select", 6);
			roiManager("Rename", "6_Homer_thresholded");
			roiManager("Deselect");
			run("Select None");
			//find Homer punctae by maxima
			run("Gaussian Blur...", "sigma=1.5 slice");
			run("Find Maxima...", "prominence=50 strict exclude output=[Point Selection]");	
			roiManager("Add");
			roiManager("Select", 7);
			roiManager("Rename", "7_Homer_punctae");
			//create Homer Areas aka spines
			run("Enlarge...", "enlarge="+dia);
			roiManager("Add");
			roiManager("Select", 8);
			roiManager("Rename", "8_All_Homer_areas");
			roiManager("Deselect");
			run("Select None");
			
			//select Homer punctae within 2µm to dendrite
			roiManager("Select", newArray(0,7));
			roiManager("AND");
			roiManager("Add");
			roiManager("Select", 9);
			roiManager("Rename", "9_dendritic HomerP");
			//create Homer punctae areas aka spines
			run("Enlarge...", "enlarge="+dia);
			roiManager("Add");
			roiManager("Select", 10);
			roiManager("Rename", "10_den_Homer_areas");
			roiManager("Deselect");

		//----------------------------------------------
		//create combinatory selections
			//all combinations of GABAARp within Homer areas and creation of corresponding areas to allow backselection onto Homer punctae
				//all GABAAR in all Homer areas
				roiManager("Select", newArray(2,8));
				roiManager("AND");
				roiManager("Add");
				roiManager("Select", 11);
				roiManager("Rename", "11_all_GABAARp_in_all_HomerA");
				
				//dendritic GABAAR in all Homer Areas
				roiManager("Select", newArray(4,8));
				roiManager("AND");
				roiManager("Add");
				roiManager("Select", 12);
				roiManager("Rename", "12_den_GABAARp_in_all_HomerA");


				//dendritic GABAAR in dendritic Homer Areas
				roiManager("Select", newArray(4,10));
				roiManager("AND");
				roiManager("Add");
				roiManager("Select", 13);
				roiManager("Rename", "13_den_GABAARp_in_den_HomerA");
				
				run("Enlarge...", "enlarge="+dia);
				roiManager("Add");
				roiManager("Select", 14);
				roiManager("Rename", "14_Areas of 13_den_GABAAR-A");
				roiManager("Deselect");
				
			//all combinations of Homer punctae within GABAAR areas
			
				//all Homers in all GABAAR areas
				roiManager("Select", newArray(7,3));
				roiManager("AND");
				roiManager("Add");
				roiManager("Select", 15);
				roiManager("Rename", "15_all_Homerp_in_all_GABAAR Areas");
				
				//all Homers in dendritic GABAAR areas
				roiManager("Select", newArray(7,5));
				roiManager("AND");
				roiManager("Add");
				roiManager("Select", 16);
				roiManager("Rename", "16_all_Homerp_in_dendritic_GABAAR Areas");

				run("Enlarge...", "enlarge="+dia);
				roiManager("Add");
				roiManager("Select", 17);
				roiManager("Rename", "17_Areas of 16_Homer-in_den_GABAAR-A");
				roiManager("Deselect");
				
		//back selection onto Homer punctae and identification of GABAAR-postive Spines
			roiManager("Select", newArray(7,17));
			roiManager("AND");
			roiManager("Add");
			roiManager("Select", 18);
			roiManager("Rename", "18_Homerp_with_GABAARS");

			run("Enlarge...", "enlarge="+dia);
			roiManager("Add");
			roiManager("Select", 19);
			roiManager("Rename", "19_Areas of GABAAR-positive Spines");
			roiManager("Deselect");

		//count of GABAAR punctae within double postive Spines
				roiManager("Select", newArray(2,19));
				roiManager("AND");
				roiManager("Add");
				roiManager("Select", 20);
				roiManager("Rename", "20_GABAARp_in_GABAARpos_Spines");



		//----------------------------------------------
		//thresholding and MPP2 ROIs
				Stack.setChannel(2);
				run("Mean...", "radius=1.5 slice");
				run("Auto Threshold", "method=RenyiEntropy white");
				run("Create Selection");
				roiManager("Add");
				roiManager("Select", 21);
				roiManager("Rename", "21_MPP2_thresholded");
				roiManager("Deselect");
				run("Select None");
				//find MPP2 punctae by maxima
				run("Gaussian Blur...", "sigma=1.5 slice");
				run("Find Maxima...", "prominence=50 strict exclude output=[Point Selection]");	
				roiManager("Add");
				roiManager("Select", 22);
				roiManager("Rename", "22_MPP2_punctae");
				//create MPP2 Areas aka spines
				run("Enlarge...", "enlarge="+dia);
				roiManager("Add");
				roiManager("Select", 23);
				roiManager("Rename", "23_All_MPP2_areas");
				roiManager("Deselect");
				
				//select MPP2 punctae within 2µm to dendrite
				roiManager("Select", newArray(0,22));
				roiManager("AND");
				roiManager("Add");
				roiManager("Select", 24);
				roiManager("Rename", "24_dendritic MPP2p");
				//create MPP2 punctae areas aka spines
				run("Enlarge...", "enlarge="+dia);
				roiManager("Add");
				roiManager("Select", 25);
				roiManager("Rename", "25_den_MPP2_areas");
				roiManager("Deselect");
				
				//count punctae within MPP2 areas and corresponding enlarged
					//select all GABAAR punctae close to all MPP2
					roiManager("Select", newArray(2,23));
					roiManager("AND");
					roiManager("Add");
					roiManager("Select", 26);
					roiManager("Rename", "26_all_GABAARp within all MPP2 areas");
					
					//select dendritic GABAAR punctae close to dendritic MPP2
					roiManager("Select", newArray(4,25));
					roiManager("AND");
					roiManager("Add");
					roiManager("Select", 27);
					roiManager("Rename", "27_den_GABAARp within den MPP2 area");
					
					//select all Homer punctae close to all MPP2
					roiManager("Select", newArray(7,23));
					roiManager("AND");
					roiManager("Add");
					roiManager("Select", 28);
					roiManager("Rename", "28_all_Homerp within all MPP2 areas");
				
					//select dendritic Homer punctae close to all  MPP2 and back selection onto MPP2
					roiManager("Select", newArray(9,23));
					roiManager("AND");
					roiManager("Add");
					roiManager("Select", 29);
					roiManager("Rename", "29_den_Homerp within all MPP2 area");
					
					run("Enlarge...", "enlarge="+dia);
					roiManager("Add");
					roiManager("Select", 30);
					roiManager("Rename", "30_den_HomerA with_allMPP2p");
					roiManager("Deselect");
					
					roiManager("Select", newArray(22,30));
					roiManager("AND");
					roiManager("Add");
					roiManager("Select", 31);
					roiManager("Rename", "31_all_MPP2p with den Homer");
						
				
					//select dendritic Homer punctae close to dendritic MPP2 and back selection onto Homer
					roiManager("Select", newArray(9,25));
					roiManager("AND");
					roiManager("Add");
					roiManager("Select", 32);
					roiManager("Rename", "32_den_Homerp within den MPP2 area");
					
					run("Enlarge...", "enlarge="+dia);
					roiManager("Add");
					roiManager("Select", 33);
					roiManager("Rename", "33_den_HomerA with_denMPP2");
					roiManager("Deselect");
					
					roiManager("Select", newArray(22,33));
					roiManager("AND");
					roiManager("Add");
					roiManager("Select", 34);
					roiManager("Rename", "34_den_MPP2p within den Homer");
						
				
				//MPP2 within GABAAR
					//select dendritic MPP2 punctae in GABAAR punctae areas and backselection onto MPP2p
					roiManager("Select", newArray(22,3));
					roiManager("AND");
					roiManager("Add");
					roiManager("Select", 35);
					roiManager("Rename", "35_all_MPP2p within all_GABAAR_areas");			

					roiManager("Select", newArray(24,5));
					roiManager("AND");
					roiManager("Add");
					roiManager("Select", 36);
					roiManager("Rename", "36_den_MPP2p within den_GABAR_areas");								
				
					run("Enlarge...", "enlarge="+dia);
					roiManager("Add");
					roiManager("Select", 37);
					roiManager("Rename", "37_MPP2 areas_36_enlarged");
					roiManager("Deselect");		

					roiManager("Select", newArray(22,37));
					roiManager("AND");
					roiManager("Add");
					roiManager("Select", 38);
					roiManager("Rename", "38_MPP2p with_GABARs");					
				
				//GABAARS within GABAARpositve MPP2
					roiManager("Select", newArray(2,37));
					roiManager("AND");
					roiManager("Add");
					roiManager("Select", 39);
					roiManager("Rename", "39_GABAARp_within_GABAARpos MPP2 areas");	
					
				//triple positives and backselection
					//HGM
					roiManager("Select", newArray(22,19));
					roiManager("AND");
					roiManager("Add");
					roiManager("Select", 40);
					roiManager("Rename", "40_MPP2p_within_GABAARpos den_Homer areas");

					run("Enlarge...", "enlarge="+dia);
					roiManager("Add");
					roiManager("Select", 41);
					roiManager("Rename", "41_MPP2 areas_40_enlarged");
					roiManager("Deselect");

					//backselection onto Homer
					roiManager("Select", newArray(9,41));
					roiManager("AND");
					roiManager("Add");
					roiManager("Select", 42);
					roiManager("Rename", "42_triple pos Homerp_HGM");
					
					run("Enlarge...", "enlarge="+dia);
					roiManager("Add");
					roiManager("Select", 43);
					roiManager("Rename", "43_triple pos HomerA_HGM");
					roiManager("Deselect");	

					//HMG
					//GABAARs within MPP2positive den Homer areas
					roiManager("Select", newArray(2,33));
					roiManager("AND");
					roiManager("Add");
					roiManager("Select", 44);
					roiManager("Rename", "44_GABAARp_within_MPP2pos den_Homer areas");

					run("Enlarge...", "enlarge="+dia);
					roiManager("Add");
					roiManager("Select", 45);
					roiManager("Rename", "45_GABAAR areas_44_enlarged");
					roiManager("Deselect");

					//backselection onto Homer
					roiManager("Select", newArray(9,45));
					roiManager("AND");
					roiManager("Add");
					roiManager("Select", 46);
					roiManager("Rename", "46_triple pos Homerp_HMG");
					
					run("Enlarge...", "enlarge="+dia);
					roiManager("Add");
					roiManager("Select", 47);
					roiManager("Rename", "47_triple pos HomerA_HMG");
					roiManager("Deselect");	
					
		
		//count and measure ROIs and write arrays
		//Homer
		arrCountAllHomerp = countPoints (l, 7, 4, arrCountAllHomerp);
		arrCountDenHomerp = countPoints (l, 9, 4, arrCountDenHomerp);
		
		arrCountHomerpWithGABAAR = countPoints (l, 18, 4, arrCountHomerpWithGABAAR);
		arrProzentGABAARposHomerOfDendritic[l] = arrCountHomerpWithGABAAR[l]/(arrCountDenHomerp[l]/100);

			arrCountHomerpWithDenMPP2 = countPoints (l, 32, 4, arrCountHomerpWithDenMPP2);
			arrProzentMPP2posDenHomerpOfDen[l] = arrCountHomerpWithDenMPP2[l]/(arrCountDenHomerp[l]/100);
			arrCountHomerpTriPosHGM = countPoints (l, 42, 4, arrCountHomerpTriPosHGM);
			arrCountHomerpTriPosHMG = countPoints (l, 46, 4, arrCountHomerpTriPosHMG);
			arrProzentTriPosHomerHMGpOfDen[l] = arrCountHomerpTriPosHMG[l]/(arrCountDenHomerp[l]/100);
			
			close("MAX_Duplicate1");
		
			//save of triple postive for quality check
			selectWindow("MAX_Duplicate3");
			run("Duplicate...", "duplicate channels=1-4");
			roiManager("Select", 47);//HMG_enlarged
			setForegroundColor(255, 255, 255);
			run("Draw", "slice");
			run("Make Composite");
			run("Select None");
			saveAs("Tiff", dir+"triples_ROIoverlay_"+imagename+Datum+Diameter+".tif");		
			run("Close");//closing of new overlay
			close("MAX_Duplicate3");

			
			//save MaxProj with enlarged ROIs for easy quality control
			selectWindow("MAX_Duplicate2");
			Stack.setChannel(4);
			roiManager("Select", 10);//den_Homer_enlarged
			run("Draw", "slice");
			Stack.setChannel(3);
			roiManager("Select", 5);//den_GABAp enlarged
			run("Draw", "slice");
			Stack.setChannel(2);
			roiManager("Select", 25);//den_MPP2_enlarged
			run("Draw", "slice");
			run("Select None");
			saveAs("Tiff", dir+"ROIoverlay_"+imagename+Datum+Diameter+".tif");
			run("Close");

		//close *.nd2 image	
	     selectWindow(imagename);
	     run("Close");

		print("-----DONE-----");

		//save&clear ROI Manager
	
		roiManager("Deselect");
		roiManager("Save", dir+imagename+Datum+Diameter+".zip");
		roiManager("Delete");

		
		
			
		}

	//write into result table


		
	}


//----------------------------------------------------------



done = false;
for(i=0;i<files.length;i++)
	{
		
		setResult("Image", i, files[i]);
		setResult("MAP2 Length", i, arrLengthDendrite[i]);
		
		setResult("All Homer Punctae", i, arrCountAllHomerp[i]);
		setResult("Den Homer Punctae", i, arrCountDenHomerp[i]);
		setResult("Homer-Spines with GABAAR", i, arrCountHomerpWithGABAAR[i]);
			setResult("Homer-SPines with MPP2", i, arrCountHomerpWithDenMPP2[i]);
			setResult("Triple Pos Homer-Spines HGM", i, arrCountHomerpTriPosHGM[i]);//should be roughly identical to arrCountHomerpTriPosHMG
			setResult("Triple Pos Homer-Spines HMG", i, arrCountHomerpTriPosHMG[i]);
		setResult("Fraction GABAARpos Homer of Den", i, arrProzentGABAARposHomerOfDendritic[i]);
			setResult("Fraction of Triple Positive dendritic Homer-Spines", i, arrProzentTriPosHomerHMGpOfDen[i]);
			setResult("Fraction of MPP2+ dendritic Homer-Spines", i , arrProzentMPP2posDenHomerpOfDen[i]);


			

		
		
		
		
	done=true;

	saveAs("results", dir+Datum+Diameter+"_Results.txt"); 
	
	}



//functions-------------------------------------------------------------------------

function measureDendriteLength (l, lengthDendrite)
	{
	
	Stack.setChannel(1);
	run("Duplicate...", 1 );
	rename("Max-1");
	run("Auto Threshold", "method=Otsu white");
	run("Gaussian Blur...", "sigma=2 slice");
	run("Make Binary", "method=Default background=Default calculate black");
	run("Open");
	run("Close-");
	run("Erode");
	run("Dilate");
	run("Create Selection");
	run("Enlarge...", "enlarge=2");
	roiManager("Add");
	roiManager("Select", 0);
	roiManager("Rename", "0_MAP2+ Dendrite perimeter");
	selectWindow("Max-1");
	run("Skeletonize", "slice");
	run("Measure Skeleton Length Tool");
	lengthDendrite[l] = getResult("length", 0);
	run("Clear Results");
	close("Max-1");
	return lengthDendrite;
	
	}


function countPoints (l, s, ch, WriteArray)
	{
	Stack.setChannel(ch);
	roiManager("Select", s);
	roiManager("Measure");
	WriteArray[l] = nResults;
	run("Clear Results");
	return WriteArray;
	}


