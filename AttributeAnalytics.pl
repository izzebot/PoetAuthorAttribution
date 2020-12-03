#!usr/bin/perl
################################################################################
#
# Attribute Based Classifiction
#
# Uses Corpus Analytics features to classify queries 
#
# Sample Document Format: 
#<P ID=A70>
#When you learn, teach. 
#When you get, give. 
#As for me,
#</P>
#
# Sample Line Output:
#	Doc ID: Author Score (repeated)
#
# Liz Sheffield * 605.744 Information Retrieval
#
#################################################################################
my $queryNumber = $ARGV[0];
my $Queries = "D:\\izzebot\\Documents\\Queries";

system("perl Statistics.pl $Queries\\Original\\$queryNumber.txt");

system("perl P_Statistics.pl $Queries\\Syllable_Based\\$queryNumber.txt");

system("perl R_Statistics.pl $Queries\\Syllable_Based\\$queryNumber.txt");