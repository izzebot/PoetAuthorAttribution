#!usr/bin/perl
################################################################################
#
# Phonological Analysis
#
# Uses the CELEX English EPW to substitute the syllable segmented pronunciation of a word
#
# 39\abbess\52\22\2\P\'{-bEs\[V][CVC]\[&][bEs]\S\'{-bIs\[V][CVC]\[&][bIs]
#
# Sample Document Format: 
#<P ID=A70>
#When you learn, teach. 
#When you get, give. 
#As for me,
#</P>
#
# Sample Output Format:
#
# Tab delimited data set: Assessment|DocID|Stanza|
#
# Liz Sheffield * 605.744 Information Retrieval
#
#################################################################################
use List::Util qw(sum);
#################################################################################
my $contains_aliteration = 0;
my $contains_repitition = 0;
my $total_lines = 0;
my $lines_containing_aliteration = 0;
my $line_containing_repitition = 0;
my $stanzaID;
my $StanzaLineCount;
my $StanzaWordCount = 0;

my @line_lengths;
my @stanza_word_counts; 
my @stanza_line_lengths; 


my %bag_of_words;
my %pronunciation;

my $CELEX = "D:\\izzebot\\Documents\\Final Project\\EPW_deDuped.txt";
my $RemediateList = "D:\\izzebot\\Documents\\Final Project\\Remediate_list.txt";

my $OUTPUT = "D:\\izzebot\\Documents\\Final Project\\PhonologyOutput.txt";
					
#################################################################################
open REMEDIATE, '>'. $RemediateList or die "Could not open file at $RemediateList\n";
open OUTPUT, '>'. $OUTPUT or die "Could not open file at $OUTPUT\n";

open (DICTIONARY,$CELEX) or die "Could not open dictionary at $CELEX\n";

while( $entry = <DICTIONARY>){
	chomp $entry;
	my @columns = split(/\\/ ,$entry);
	$word = $columns[1];
	$word =~ tr/[A-Z]/[a-z]/;
	$phonology = $columns[-1];
	
	if ((exists $pronunciation{$word}) && ($pronunciation{$word} ne $phonology)){
		$pronunciation{$word} = "*MRN:$word*";
		print REMEDIATE "$word $columns[0]\n";
	}
	else{
		$pronunciation{$word} = $phonology;
	}
}

open (COLLECTION,$ARGV[0]) or die "Could not open collection at $ARGV[0]\n";

while( $line = <COLLECTION>){
	if($line !~ m/^</){
		chomp $line;
		$line =~ s/[[:punct:]]//g;
		$line =~ tr/[A-Z]/[a-z]/;
		# decompse the line to words, sub out words
		chomp $line;
		my @lineSet = split(/\s/ ,$line);
		my @pronunciations;
		$length = $#lineSet;
		for $x (0 .. $length){
			if (exists $pronunciation{$lineSet [$x]}){
				push @pronunciations, $pronunciation{$lineSet [$x]};
			}
			else{
				push @pronunciations, "unknown $lineSet[$x]";
			}
		}
		#print "$line\n";
		print OUTPUT "@pronunciations\n"
	}
	else {
		print OUTPUT "$line";
	}
}

END