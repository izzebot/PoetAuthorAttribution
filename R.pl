open (COLLECTION,$ARGV[0]) or die "Could not open collection at $ARGV[0]\n";

while( $line = <COLLECTION>){

	chomp($line);
	$line_length = length $line;
	if($line =~ /<P ID=(.*)>/){
		$stanzaID = $1;
	}
	
	if(($line !~ m/^</) && ($line_length >= 1)){
		print "$line\n";
		my @lineSet = split(/\s/ ,$line);
		
		$length = $#lineSet;
		
		my $last_word = $lineSet[-1];
		
		#removes syllable brackets
		$last_word =~ s/[[\[\]]//g;
		my $reversed_last_word = reverse $last_word;
		print "$reversed_last_word\n";
		
		my $letter = substr $reversed_last_word, 0, 1;
		print "$letter\n";

	}
	
	if($line =~ /<\/P>/){
		#check_Stanza_Rhyming_Lines($line_Count, @LastWords);
		$line_Count =0;
		undef(@LastWords);
	}
	
}

#A line rhymes if the last CV / VC pair matches
sub check_Stanza_Rhyming_Lines{
	my ($numOfLines, @LineEndings) = @_;
	$length = $#LineEndings+1;

	print "@LineEndings\n";
}

@short_vowels= qw(
					I Y E / { &
					A V	O U @ c
					3 ,
				);		
@long_vowels= qw!
					i # a $ u 3 y
					e | o 1 2 4 )
					6 W B X ^ q 0
					:
				!;
@consonants = qw(
					p b t d k g N m
					n l r f v T D s 
					z S Z j x h w + 
					= J	*
				);