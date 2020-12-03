use 5.016;

$, = ' ';
$\ = "\n";

my %stop = map {fc, 1} qw{
    I a about an and are as at be by com for from how in is it of on or that
    the this to was what when where who will with
};

while (<>) {
    my (@allit, $initial);
    for (split) {
        next if $stop{fc $_};
        s/\W//g;
        my $new_initial = fc substr $_, 0, 1;
        push @allit, [] if $initial ne $new_initial;
        $initial = $new_initial;
        push @{$allit[-1]}, $_;
    }
    print map {@$_} grep {@$_ >= 2} @allit;
}