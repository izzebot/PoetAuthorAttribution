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

my %docAssessments;
my %features;
my %docFeatureOccurances; #Will be a hash of hashes for each doc and each feature that occurs within that doc. 

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
	system("svm_multiclass_learn -c .01 Training_Feature_Vectors.dat binary_model");
	
#Step 4: Classify Queries with SVMmulticlass;
	system("svm_multiclass_classify Query_Feature_Vectors.dat binary_model test_predictions");
	
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
	if(exists $stopHash{$toBeChecked}){
		if(!exists($features{$toBeChecked})){
			$features{$toBeChecked}=$currentFeatureID;
			$currentFeatureID++;
			print FEATUREFILE "$toBeChecked|$features{$toBeChecked}\n"; #creates a Lookup File of ID + Feature for use later.
		}
		$docFeatureOccurances{$currentDocID}{$features{$toBeChecked}}++; #increases the occurances for a given featureID for a given DocID
	}
	#Print out the feature and ID
	#print "DocID: $currentDocID, Feature: $toBeChecked, FeatureID: $features{$toBeChecked}\n";
}

#Writes the vectors out to a file to be used for the SVMlight Trainer and Classifier
sub output_Vector{
	my ($Output) = @_;
	open OUTPUT, '>'. $Output or die "Could not open file at $Output\n";
	for $docID( sort keys %docAssessments ) {
		print OUTPUT "$docAssessments{$docID} ";
		for $feature ( sort {$a<=>$b} keys %{ $docFeatureOccurances{$docID} } ) {
			print OUTPUT "$feature:1 ";
		}
		print OUTPUT " # $docID\n";
		delete $docAssessments{$docID};
	}
}