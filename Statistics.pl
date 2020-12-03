#!usr/bin/perl
################################################################################
#
# Aliteration test
#
# Performs Text Analysis to determine if a line contains aliteration or repitition.
# Determines average line length, and average stanza length
#
# Sample Document Format: 
#<P ID=A70>
#When you learn, teach. 
#When you get, give. 
#As for me,
#</P>
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

my @stopWords = ("a","about","an","and","are","as","at","be", "but", "by","for","from","he","her","hers","him",
					"his","how","has","i","in","me","my","mine","is","it","its","of","on","or","she","that","the",
					"they","them","their","theirs","to","was","","we","what","when","where","who","were","will","with","you","your","yours");

#################################################################################
@stopHash{@stopWords}=();

open (COLLECTION,$ARGV[0]) or die "Could not open collection at $ARGV[0]\n";
while( $line = <COLLECTION>){
	chomp($line);
	$line_length = length $line;
	if($line =~ /<P ID=(.*)>/){
		$stanzaID = $1;
	}
	
	if(($line !~ m/^</) && ($line_length >= 1)){
		$StanzaLineCount++; #increases count of the lines in the stanza
		$total_lines++;
		$line =~ s/[[:punct:]]//g;
		$line =~ tr/[A-Z]/[a-z]/;
		my @lineSet = split(/\s/ ,$line);
		$length = $#lineSet;
		# add line length to array 
		push @line_lengths, $length;
		$StanzaWordCount += $length;
		repitition_Check($line, $length, @lineSet);
		#purposely starting array at 1 because comparing to the word that came before
		for $x (1 .. $length-1){
				if(!exists $stopHash{$lineSet[$x]} && !exists $stopHash{$lineSet[$x-1]}){
					$current_word_first_letter = substr($lineSet[$x], 0, 1);
					$previousword_word_first_letter = substr($lineSet[$x-1], 0, 1);
				
					if ($current_word_first_letter eq $previousword_word_first_letter ){
						#print "found  $current_word_first_letter $previousword_word_first_letter $lineSet[$x] $lineSet[$x-1] aliteration in line $line\n";
						$contains_aliteration = 1;
					}
					else{
					
					}
				}

			}
		if ($contains_aliteration){
			#print "found aliteration in line $line\n";
			$lines_containing_aliteration++;
		}
		$contains_aliteration = 0;
	}
	
	if($line =~ /<\/P>/){
		push @stanza_line_lengths, $StanzaLineCount;
		push @stanza_word_counts, $StanzaWordCount;
		$StanzaWordCount =0;
		$StanzaLineCount =0;
	}
	
}
QueryMeanandMedian();
print "Scanned $total_lines lines and found $lines_containing_aliteration lines containing aliteration and $line_containing_repitition containing repitition";

sub repitition_Check{
	my ($line, $arrayLength, @lineArray) = @_;
	for $y (0 .. $arrayLength-1){
		if(!exists $stopHash{$lineArray[$y]}){
			$bag_of_words{$lineArray[$y]}++;
		}
	}
	foreach $key (keys %bag_of_words){
		if ($bag_of_words{$key}>1){
			#print "found repitition in $line\n";
			$line_containing_repitition++;
		}
		delete $bag_of_words{$key};
	}
}

sub QueryMeanandMedian{
	my @sortedStanzaLengths = sort { $a <=> $b} @stanza_line_lengths;
	my @sortedLineLengths = sort { $a <=> $b} @line_lengths;
	my @sortedStanzaWordCounts = sort { $a <=> $b} @stanza_word_counts;
	
	my $stanzaWordMean = sum(@sortedStanzaWordCounts)/@sortedStanzaWordCounts;
	my $StanzaMean = sum(@sortedStanzaLengths)/@sortedStanzaLengths;
	my $LineMean = sum(@sortedLineLengths)/@sortedLineLengths;
	
	my $stanzaWordMedian = Median(@sortedStanzaWordCounts);
	my $StanzaMedian =  Median(@sortedStanzaLengths);
	my $LineMedian =  Median(@sortedLineLengths);
	
	print "The Stanza Word mean is $stanzaWordMean and the median is $stanzaWordMedian\n";
	print "The Stanza Line mean is $StanzaMean and the median is $StanzaMedian\n";
	print "The Line Word mean is $LineMean and the median is $LineMedian\n";
}

#Function returns the median of an array
sub Median{
	my (@Lengths) = @_;
	my $arrayLength = @Lengths;
	if ($arrayLength%2){
		return $Lengths[int($arrayLength/2)];
	}
	else{
		return ($Lengths[int($arrayLength/2)-1] + $Lengths[int($arrayLength/2)]/2);
	}
}



