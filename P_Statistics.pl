#!usr/bin/perl
################################################################################
#
# Phonology Statistics
#
# Performs Text Analysis to determine average syllables per line, per stanza, per word.
# Determines average line length, and average stanza length
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


my $LineSyllableCount = 0;
my $StanzaSyllableCount = 0;


my @word_syllable_counts; 
my @line_syllable_counts;
my @stanza_syllable_counts;

my %num_of_x_syllable_words;

#################################################################################

open (COLLECTION,$ARGV[0]) or die "Could not open collection at $ARGV[0]\n";
while( $line = <COLLECTION>){
	chomp($line);
	$line_length = length $line;
	if($line =~ /<P ID=(.*)>/){
		$stanzaID = $1;
	}
	
	if(($line !~ m/^</) && ($line_length >= 1)){
		my @lineSet = split(/\s/ ,$line);
		$length = $#lineSet; #this is equal to the words per line
		for $x (0 .. $length){
			my $word = $lineSet[$x];
			my @WordSyllables = split(/]/ ,$word);
			
			my $Word_Syllable_count = $#WordSyllables+1;
			$wordCount++;
			$num_of_x_syllable_words{$Word_Syllable_count}++;
			
			$LineSyllableCount += $Word_Syllable_count;
			#print "$lineSet[$x] has $Word_Syllable_count syllables\n";
			push @word_syllable_counts, $Word_Syllable_count;
		}
		push @line_syllable_counts, $LineSyllableCount;
		$StanzaSyllableCount += $LineSyllableCount;
		$LineSyllableCount = 0;
	}
	
	if($line =~ /<\/P>/){
		push @stanza_syllable_counts, $StanzaSyllableCount;
		$StanzaSyllableCount = 0;
	}
	
}
QueryMeanandMedian();
foreach my $key (keys(%num_of_x_syllable_words)){
	my $percentOfWords = $num_of_x_syllable_words{$key}/$wordCount;
	print "There are $num_of_x_syllable_words{$key} $key syllable words ($percentOfWords)\n";
}

sub QueryMeanandMedian{

	my @sortedStanzaSyllableCounts = sort { $a <=> $b} @stanza_syllable_counts;
	my @sortedLineSyllableCounts = sort { $a <=> $b} @line_syllable_counts;
	my @sortedWordSyllableCounts = sort { $a <=> $b} @word_syllable_counts;
		
	my $stanzaSyllableMean = sum(@sortedStanzaSyllableCounts)/@sortedStanzaSyllableCounts;
	my $lineSyllableMean = sum(@sortedLineSyllableCounts)/@sortedLineSyllableCounts;
	my $wordSyllableMean = sum(@sortedWordSyllableCounts)/@sortedWordSyllableCounts;
	
	my $stanzaSyllableMedian = Median(@sortedStanzaSyllableCounts);
	my $lineSyllableMedian =  Median(@sortedLineSyllableCounts);
	my $wordSyllableMedian =  Median(@sortedWordSyllableCounts);
	
	print "The Stanza Syllable mean is $stanzaSyllableMean and the median is $stanzaSyllableMedian\n";
	print "The Line Syllable mean is $lineSyllableMean and the median is $lineSyllableMedian\n";
	print "The Word Syllable mean is $wordSyllableMean and the median is $wordSyllableMedian\n";
}

#Function returns the median of an array
sub Median{
	my (@Lengths) = @_;

	my $arrayLength = $#Lengths;
	
	if ($arrayLength == 0){
		return $Lengths[0];
	}
	elsif ($arrayLength%2){
		return $Lengths[int($arrayLength/2)];
	}
	else{
		return ($Lengths[int($arrayLength/2)-1] + $Lengths[int($arrayLength/2)]/2);
	}
}



