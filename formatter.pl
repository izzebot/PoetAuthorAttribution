#!usr/bin/perl
################################################################################
#
# Format for Classifier 
#
# Formats in tab deliminated fields for the classifier 
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
my $stanzaID;
my @stanzaLines;

my $outputFile = "D:\\izzebot\\Documents\\Final Project\\query_corpus.txt";

#################################################################################
open (COLLECTION,$ARGV[0]) or die "Could not open collection at $ARGV[0]\n";
open OUTPUT, '>>'. $outputFile;

while( $line = <COLLECTION>){
	chomp($line);
	$line_length = length $line;
	if($line =~ /<P ID=(.*)>/){
		$stanzaID = $1;
	}
	if($line !~ m/^</){
		$line =~ s/\t//g;
		push @stanzaLines, $line;
	}
	if($line =~ /<\/P>/){
	 print OUTPUT "Q\t$stanzaID\t@stanzaLines\n";
	 undef(@stanzaLines);
	}
}