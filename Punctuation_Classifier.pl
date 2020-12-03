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

my %docAssessments;
my %features;
my %docFeatureOccurances; #Will be a hash of hashes for each doc and each feature that occurs within that doc. 
my %docFeatureCount; #Will be a hash of the number of features in each doc
my %TermIDFs; #stores the IDfs for each term;
my %docLengths;
my %docTermVectors; #Stores the Eucliedean Noramlizaed Document Vectors for each term for each document


my $FeatureLookupFile = "D:\\izzebot\\Documents\\Final Project\\Features.txt";
my $TrainOutput = "D:\\izzebot\\Documents\\Final Project\\Training_Feature_Vectors.dat";
my $QueryOutput = "D:\\izzebot\\Documents\\Final Project\\Query_Feature_Vectors.dat";
my $Queries = "D:\\izzebot\\Documents\\Final Project\\query_corpus.txt";
my $Corpus = "D:\\izzebot\\Documents\\Final Project\\training_corpus.txt";
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
	system("svm_multiclass_learn -c .5 Training_Feature_Vectors.dat p_tfidf_model");
	
#Step 4: Classify Queries with SVMmulticlass;
	system("svm_multiclass_classify Query_Feature_Vectors.dat p_tfidf_model test_predictions");
	
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
	
	#Next remove alpha numeric characters leaving only punctuation
	$toBeChecked =~ s/[[:alnum:]]//g;
	if(!exists($features{$toBeChecked})){
		$features{$toBeChecked}=$currentFeatureID;
		$currentFeatureID++;
		print FEATUREFILE "$toBeChecked|$features{$toBeChecked}\n"; #creates a Lookup File of ID + Feature for use later.
	}
	$docFeatureOccurances{$currentDocID}{$features{$toBeChecked}}++; #increases the occurances for a given featureID for a given DocID
	$docFeatureCount{$currentDocID}++;
	$term = $features{$toBeChecked}; 
	if ($training){$wordCollectionFreq{$term}++;}
	#Print out the feature and ID
	#print "DocID: $currentDocID, Feature: $toBeChecked, FeatureID: $features{$toBeChecked}\n";
}

#Writes the vectors out to a file to be used for the SVMlight Trainer and Classifier
sub output_Vector{
	my ($Output) = @_;
	open OUTPUT, '>'. $Output or die "Could not open file at $Output\n";
	for $docID( sort keys %docAssessments ) {
		print OUTPUT "$docAssessments{$docID} ";
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