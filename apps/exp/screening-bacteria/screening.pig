--
-- filters a set of reads based on shared kmer
--
-- this is for alex's use.  given a set of reads and a set data (both sequence files), it filters
-- the data such that all sequences that pass the filter have at least 1 kmer shared with the
-- reads.  we asssume that size of reads >> size of data.
--
-- commandline parameters include:
--    reads        - the reads
--    data         - the datafile
--    outputdir    - the directory to put output results
--    p            - degree of parallelism to use for reduce operations

%default p '300'

register /global/homes/k/kbhatia/pipelinelibrary-0.1.1-job.jar

A = load '$reads' using gov.jgi.meta.pig.storage.FastaStorage as (readid: chararray, d: int, seq: bytearray, header: chararray); 
B = foreach A generate readid, FLATTEN(gov.jgi.meta.pig.eval.KmerGenerator(seq, 30)) as (kmer:bytearray);
C = distinct B PARALLEL $p;

W = load '/users/kbhatia/SAG_Screening/ntindex' as (dataid: chararray, kmer:bytearray) ;

-- join B with T
L = join W by kmer, C by kmer PARALLEL $p;
M = foreach L generate W::dataid, C::readid;
N = group M by (W::dataid, C::readid) PARALLEL $p;
O = foreach N generate group.C::readid, group.W::dataid, COUNT(M) as numhits;
P = group O by C::readid ;
R = foreach P {
    R1 = order O by numhits DESC ;
    R2 = limit R1 1;
    generate FLATTEN(R2);
};

store R into '$output';


