# docker-alignment
Docker image for alignment.

## Pre-align
```bash
samtools view -uh -F 0x900 $local_input_file \
  | bam-ext-mem-sort-manager squeeze --in -.ubam --keepDups --rmTags AS:i,BD:Z,BI:Z,XS:i,MC:Z,MD:Z,NM:i,MQ:i --out -.ubam \
  | samtools sort -l 1 -@ 1 -n -T <pre_output_base>.samtools_sort_tmp - \
  | samtools fixmate - - \
  | bam-ext-mem-sort-manager bam2fastq --in -.bam --outBase <pre_output_base> --maxRecordLimitPerFq 20000000 --sortByReadNameOnTheFly --readname --gzip
```


## Align
```bash
ref_path=<ref_path>
pre_output_base=<pre_output_base>

while read line
do
  line_rg=$(echo $line | cut -d ' ' -f 4- | sed -e "s/ /\\\t/g")
  input_path=$(echo $line | cut -f 2 -d ' ')
  input_filename=$(basename $input_path)
  output_filename=$(basename $input_filename ".fastq.gz").cram

  paired_flag=""
  if [[ $input_file_name =~ interleaved\.fastq\.gz$ ]]
  then
    paired_flag="-p"
  fi

  bwa mem -t 32 -K 100000000 -Y ${paired_flag} -R "$line_rg" $ref_path $input_path | samblaster -a --addMateTags | samtools view -@ 32 -T $ref_path -C -o $output_filename - 
done <<< "$(tail -n +2 ${pre_output_base}.list)"
```

## Post-align
```bash
input_dir=<input_dir>
ref_path=<ref_path>
dbsnp_path=<dbsnp_path>
rc=0
for input_file in ${input_dir}/*.cram 
do 
  tmp_prefix=${input_file%.cram}.tmp
  samtools sort --reference /home/alignment/ref/hs38DH.fa --threads 1 -T $tmp_prefix -o ${input_file%.cram}.sorted.bam $input_file
  rc=$?
  [[ $rc != 0 ]] && break
  rm -f $input_file ${tmp_prefix}*
done

if [[ $rc == 0 ]]
then 
  samtools merge --threads 1 -c ${input_dir}/merged.bam ${input_dir}/*.sorted.bam \
    && rm ${input_dir}/*.sorted.bam \
    && bam-non-primary-dedup dedup_LowMem --allReadNames --binCustom --binQualS 0:2,3:3,4:4,5:5,6:6,7:10,13:20,23:30 --log ${input_dir}/dedup_lowmem.metrics --recab --in ${input_dir}/merged.bam --out -.ubam --refFile $ref_path --dbsnp $dbsnp_path \
    | samtools view -h -C -T ${ref_path} -o ${input_dir}/output.cram --threads 1
  rc=$?
fi
```