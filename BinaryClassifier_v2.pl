#!usr/bin/perl
################################################################################
#
# Binary Text Classifiction
#
# Uses Binary Occuraces to determine classification
#
# Sample Document Format: 
#	Tab delimited data set: Class|DocID|Stanza
#
# Sample Line Output:
#	Space delimited data: target|feature:occurance (repeat for each feature occuring)
#
# Liz Sheffield * 605.744 Information Retrieval
#
#################################################################################
my $currentDocID = 0;
my $currentAssessment = 0;
my $currentFeatureID = 1;
my $training = 1;
my $numberCorrectlyPredictedFromDevFile = 0;
my $numberCorrectlyPredictedFromOutputFile= 0;
my $numberInCorrectlyPredicted = 0;
my $plusOneDevFileCount = 0;
my $plusOneOutputFileCount = 0;

my %docAssessments;
my %features;
my %docFeatureOccurances; #Will be a hash of hashes for each doc and each feature that occurs within that doc. 

my $FeatureLookupFile = "D:\\izzebot\\Documents\\Final Project\\Features.txt";
my $TrainOutput = "D:\\izzebot\\Documents\\Final Project\\Training_Feature_Vectors.dat";
my $QueryOutput = "D:\\izzebot\\Documents\\Final Project\\Query_Feature_Vectors.dat";
my $Queries = "D:\\izzebot\\Documents\\Final Project\\query_corpus.txt";
my $Corpus = "D:\\izzebot\\Documents\\Final Project\\training_corpus.txt";
my $PredictionOutput = "D:\\izzebot\\Documents\\Final Project\\sheffied-predictions.txt";
my $SVM_Prediction_Results = "D:\\izzebot\\Documents\\Final Project\\test_predictions";

#################################################################################
open FEATUREFILE, '>'. $FeatureLookupFile or die "Could not open file at $FeatureLookupFile\n";

#Step 1: Read in lines and split to features for the Train Set
	open (COLLECTION,$Corpus) or die "Could not open collection at $Corpus\n";
	#read in line in the dataset
		while( $line = <COLLECTION>){
			split_line($line);
		}
	close COLLECTION;
	close FEATUREFILE;
#Step 2: Create Output for Learner;
	output_Vector($TrainOutput);
	$training = 0; 
	open (COLLECTION,$Queries) or die "Could not open collection at $Queries\n";
	#read in line in the dataset
		while( $line = <COLLECTION>){
			split_line($line);
	}
	output_Vector($QueryOutput);
	
#Step 3: Train SVMmulticlass;
	system("svm_learn Training_Feature_Vectors.dat binary_model");
	
#Step 4: Classify Queries with SVMmulticlass;
	system("svm_classify Query_Feature_Vectors.dat binary_model test_predictions");

#Step 5: Read Results and Produce Predictions
	compare_results($SVM_Prediction_Results,$QueryOutput);
	
	my $Recall = compute($plusOneDevFileCount,$numberCorrectlyPredictedFromDevFile, "Recall: ");
	my $Precision = compute($plusOneOutputFileCount, $numberCorrectlyPredictedFromOutputFile, "Precision: ");
	
	my $F1 = 0;
	if ($Precision+$Recall == 0){
		$F1 = 0;
	}
	else{
		$F1 = 2*$Precision*$Recall/($Precision+$Recall);
	}
	print "Recall: $Recall, Precision: $Precision, F1: $F1\n";
		
END;

#Splits the lines by tabs 
sub split_line(){
	my ($line) = @_;
	my @lineSet = split(/\t/ ,$line); #splits line into an array on tabs. [0] = Class, [1] = DocID, [2] = Stanza
	$currentDocID = @lineSet[1];
	$currentAssessment = @lineSet[0];
	$docAssessments{$currentDocID} = $currentAssessment; #keeps track of the assessment for each DocID.
	
	examine_line(@lineSet[2]); #splits the Stanza into tokens
}

sub examine_line{
	my ($line) = @_;
	#Splits on space
	my @tokens = split /\s+/, $line;
	foreach $item (@tokens){
		#normalizes the tokens
		evaluate_token($item);
	}
}
sub evaluate_token{
	my ($toBeChecked) = @_;
	
	#Start by making everything lower case, this will be important in determining frequency
	$toBeChecked =~ tr/[A-Z]/[a-z]/;
	
	#Next remove punctuation, this is will completely strip preceeding, trailing, and internal punctuation, thereby reducing contractions such as isn't to isnt
	$toBeChecked =~ s/[[:punct:]]//g;
	if(!exists($features{$toBeChecked})){
		$features{$toBeChecked}=$currentFeatureID;
		$currentFeatureID++;
		print FEATUREFILE "$toBeChecked|$features{$toBeChecked}\n"; #creates a Lookup File of ID + Feature for use later.
	}
	$docFeatureOccurances{$currentDocID}{$features{$toBeChecked}}++; #increases the occurances for a given featureID for a given DocID
	#Print out the feature and ID
	#print "DocID: $currentDocID, Feature: $toBeChecked, FeatureID: $features{$toBeChecked}\n";
}

#Writes the vectors out to a file to be used for the SVMlight Trainer and Classifier
sub output_Vector{
	my ($Output) = @_;
	open OUTPUT, '>'. $Output or die "Could not open file at $Output\n";
	for $docID( sort keys %docAssessments ) {
		if($docAssessments{$docID}==5){
			#print OUTPUT "$docAssessments{$docID} ";
			print OUTPUT "+1 ";
		}
		else{
			print OUTPUT "-1 ";
		}

		for $feature ( sort {$a<=>$b} keys %{ $docFeatureOccurances{$docID} } ) {
			print OUTPUT "$feature:1 ";
		}
		print OUTPUT " # $docID\n";
		delete $docAssessments{$docID};
	}
}
#Looks at the output from the SVM Predictions and validates the results against the data set to 
sub compare_results{
	my ($resultsFile, $vectorFile) =@_;
	open (RESULTS,$resultsFile) or die "Could not open SVM RESULTS at $resultsFile\n";
	open (VECTORS,$vectorFile) or die "Could not open Vector File at $vectorFile\n";
	open OUTPUT, '>'. $PredictionOutput or die "Could not open file at $Output\n";
	
	chomp (@Result_Lines = <RESULTS>);
	$currentVector = 0;
	while ($line = <VECTORS>){

		my @elements = split /\s+/, $line;
		compute_Recall_Stats(@elements[0],@Result_Lines[$currentVector]);
		
		#Checks if SVM predicted the document to be in the class
		if (@Result_Lines[$currentVector]=~ /^\d/){
			$plusOneOutputFileCount++;
			if (@elements[0]=~ /^[+]/){$numberCorrectlyPredictedFromOutputFile++;} #Checks if the document was assessed to be in the class (correct Prediction)
			print OUTPUT "$elements[$#elements]\t1\n"; # Prints the DocID [tab] prediction;
		}
		else{
			print OUTPUT "$elements[$#elements]\t-1\n"; # Prints the DocID [tab] prediction;
		}
		$currentVector++;
	}
	close RESULTS;
	close VECTORS;
	close OUTPUT;
}
#Checks if the document was assessed to be in the class
sub compute_Recall_Stats{
	my ($Assessment, $Prediction) =@_;
	if ($Assessment=~ /^[+]/){
		$plusOneDevFileCount++;
			if ($Prediction=~ /^\d/){
			$numberCorrectlyPredictedFromDevFile++;} #Checks if SVM correctly predicted it to be in the Hash
	}
}
#Computes Recall or Precision depending on variables passed;
sub compute{
	my ($Total, $Correct, $Calculation) = @_;
	print "Calculating $Calculation$Correct / $Total \n";
	if ($Total == 0){
		return 0;
	}
	else{
		return $Correct / $Total;
	}
}