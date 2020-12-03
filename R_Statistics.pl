#!usr/bin/perl
################################################################################
#
# Rhyming Statistics
#
# Performs Text Analysis isolate the last word of each line and check if another line in the stanza rhymes
#
# Sample Document Format: 
#<P ID=A37>
#[meI][bI]
#</P>
#
# Liz Sheffield * 605.744 Information Retrieval
#
#################################################################################
use List::Util qw(sum);
#################################################################################

my $wordCount;
my $stanzaID;
my $line_Count;
my $test =0;my $containsRhymes = 0;
my @vowels;
my @LastWords;
my %Substrings;

my $stanzaCount = 0;
my $rhyming_stanza;
#################################################################################

open (COLLECTION,$ARGV[0]) or die "Could not open collection at $ARGV[0]\n";
while( $line = <COLLECTION>){
	chomp($line);
	$line_length = length $line;
	if($line =~ /<P ID=(.*)>/){
		$stanzaID = $1;
		$stanzaCount++;
	}
	
	if(($line !~ m/^</) && ($line_length >= 1)){		#print "$line\n";
		my @lineSet = split(/\s/ ,$line);
				$length = $#lineSet;		
		my $last_word = $lineSet[-1];
		
		#removes syllable brackets
		$last_word =~ s/[[\[\]]//g;
		my $reversed_last_word = reverse $last_word;
		#print "$reversed_last_word\n";
		my $substring = substr $reversed_last_word, 0, 3;		$Substrings{$substring}++;
	}
	
	if($line =~ /<\/P>/){
		foreach my $key (keys(%Substrings)){
			if($Substrings{$key}>1){

				$containsRhymes = 1;
			}
			delete $Substrings{$key};
		}
		if ($containsRhymes){
			$rhyming_stanza++;
			$containsRhymes = 0;
		}
	}
	
}

print "$rhyming_stanza out of $stanzaCount contained rhyming lines\n";

#A line rhymes if the last CV / VC pair matches
sub check_Stanza_Rhyming_Lines{
	my ($numOfLines, @LineEndings) = @_;
	$length = $#LineEndings+1;

	print "@LineEndings\n";
}