#!usr/bin/perl
################################################################################
#
# Text Classifiction
#
# Uses Document Sensitive Occuraces to determine classification
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
my $documentCount = 0;
my $tf_idf;
my $numberCorrectlyPredictedFromDevFile = 0;
my $numberCorrectlyPredictedFromOutputFile= 0;
my $numberInCorrectlyPredicted = 0;
my $plusOneDevFileCount = 0;
my $plusOneOutputFileCount = 0;

my %docAssessments;
my %features;
my %docFeatureOccurances; #Will be a hash of hashes for each doc and each feature that occurs within that doc. 
my %docFeatureCount; #Will be a hash of the number of features in each doc
my %TermIDFs; #stores the IDfs for each term;
my %docLengths;
my %docTermVectors; #Stores the Eucliedean Noramlizaed Document Vectors for each term for each document
#my @stopWords = ("a","about","an","and","are","as","at","be", "but", "by","for","from","he","her","hers","him",
#					"his","how","has","i","in","me","my","mine","is","it","its","of","on","or","she","that","the",
#					"they","them","their","theirs","to","was","","we","what","when","where","who","were","will","with",
#					"you","your","yours", "can", "do", "dont", "will", "why", "not" 
#					);
my @stopWords = ("he","her","hers","him",
					"his","i","me","my","mine","it","its","she","that",
					"they","them","their","theirs","we",
					"you","your","yours"
					);


my $FeatureLookupFile = "D:\\izzebot\\Documents\\Final Project\\Features.txt";
my $TrainOutput = "D:\\izzebot\\Documents\\Final Project\\Training_Feature_Vectors.dat";
my $QueryOutput = "D:\\izzebot\\Documents\\Final Project\\Query_Feature_Vectors.dat";
my $Queries = "D:\\izzebot\\Documents\\Final Project\\query_corpus.txt";
my $Corpus = "D:\\izzebot\\Documents\\Final Project\\training_corpus.txt";
my $PredictionOutput = "D:\\izzebot\\Documents\\Final Project\\sheffied-predictions.txt";
my $SVM_Prediction_Results = "D:\\izzebot\\Documents\\Final Project\\sw_tfidf_test_predictions";
#################################################################################
@stopHash{@stopWords}=();
open FEATUREFILE, '>'. $FeatureLookupFile or die "Could not open file at $FeatureLookupFile\n";

#Step 1: Read in lines and split to features for the Train Set
	open (COLLECTION,$Corpus) or die "Could not open collection at $Corpus\n";
	#read in line in the dataset
		while( $line = <COLLECTION>){
			split_line($line);
		}
	close COLLECTION;
	close FEATUREFILE;
	compute_idf();
	compute_Normalized_Vectors();
	output_Vector($TrainOutput);
#Step 2: Create Output for Learner;

	$training = 0; 
	open (COLLECTION,$Queries) or die "Could not open collection at $Queries\n";
	#read in line in the dataset
		while( $line = <COLLECTION>){
			split_line($line);
	}
	compute_idf();
	compute_Normalized_Vectors();
	output_Vector($QueryOutput);
	
#Step 3: Train SVMmulticlass;
	#system("svm_multiclass_learn -c .5 Training_Feature_Vectors.dat sw_tfidf_model");
	system("svm_learn Training_Feature_Vectors.dat sw_tfidf_model");

	
#Step 4: Classify Queries with SVMmulticlass;
	#system("svm_multiclass_classify Query_Feature_Vectors.dat sw_tfidf_model sw_tfidf_test_predictions");
	system("svm_classify Query_Feature_Vectors.dat sw_tfidf_model sw_tfidf_test_predictions");


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
	$documentCount++;
	
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
	#this classifier only looks at stopwords 
	if(exists $stopHash{$toBeChecked}){
		if(!exists($features{$toBeChecked})){
		$features{$toBeChecked}=$currentFeatureID;
		$currentFeatureID++;
		print FEATUREFILE "$toBeChecked|$features{$toBeChecked}\n"; #creates a Lookup File of ID + Feature for use later.
		}
		$docFeatureOccurances{$currentDocID}{$features{$toBeChecked}}++; #increases the occurances for a given featureID for a given DocID
		$docFeatureCount{$currentDocID}++;
		$term = $features{$toBeChecked}; 
		if ($training){$wordCollectionFreq{$term}++;}
	}

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

		#print OUTPUT "$docAssessments{$docID} ";
		for $feature ( sort {$a<=>$b} keys %{ $docTermVectors{$docID} } ) {
		#my $featureShare = $docFeatureOccurances{$docID}{$feature}/$docFeatureCount{$docID};
		my $featureShare = $docTermVectors{$docID}{$feature};
			print OUTPUT "$feature:$featureShare ";
		}
		print OUTPUT " # $docID\n";
		delete $docAssessments{$docID};
	}
}

#computes the IDFs for each term
sub compute_idf{
	foreach $term (keys %wordCollectionFreq){
		$value = $documentCount/$wordCollectionFreq{$term};
		$TermIDFs{$term} = (log($value)/log(2));
		#print "$term $wordCollectionFreq{$term} idf is $TermIDFs{$term}\n";
		
	}
}
#Computes the tf-idf for a given term and term frequency
sub compute_tf_idf{
	my ($term, $tf) = @_;
	$tf_idf = $tf * $TermIDFs{$term};
	#print "for term $term $tf_idf calucluated as $tf times $TermIDFs{$term}\n";
}
#computes the Normalized vectors for each term in each document
sub compute_Normalized_Vectors{
	for $doc( keys %docFeatureOccurances ) {
		compute_Euclidean_Length($doc);
		for $term ( keys %{ $docFeatureOccurances{$doc} } ) {
			compute_tf_idf($term, $docFeatureOccurances{$doc}{$term});
			if ($docLengths{$doc} != 0){$docTermVectors{$doc}{$term} = ($tf_idf / $docLengths{$doc});}
			else {$docTermVectors{$doc}{$term} = 0;}
			#print "for doc: $doc, $term normalized vector: $docTermVectors{$doc}{$term}\n";
		}
	}
}

#computes the EuclideanLength for a given document
sub compute_Euclidean_Length{
#given a doc, compute the length
	my($doc) = @_;
	$SumOfSquares = 0;
	for $term ( keys %{ $docFeatureOccurances{$doc} } ) {	
		compute_tf_idf($term, $docFeatureOccurances{$doc}{$term});
		#print "$doc $term $tf_idf\n";
		#print "Sum of Squares is currently $SumOfSquares, $term occurs $docFeatureOccurances{$doc}{$term} times\n";
		$SumOfSquares += ($tf_idf**2);
	}
	#print "$doc: $SumOfSquares\n";
	$EuclideanLength = sqrt($SumOfSquares);
	$docLengths{$doc} = $EuclideanLength;
	#print "$doc: EL: $docLengths{$doc}\n";
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