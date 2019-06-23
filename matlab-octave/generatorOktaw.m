clear all
%przenoszenie bazowego zestawu dźwięków do kolejnych oktaw:
%dopisywanie przecinków/apostrofów

plikDzw='wysokosci0.txt';
fid=fopen(plikDzw,'r');
wys=cell2mat(textscan(fid,'%s'));
fclose(fid);
okt={',,,',',,',',','',char(39),repmat(char(39),1,2),repmat(char(39),1,3),repmat(char(39),1,4)};

plikOkt='dzwiekiOktChrom.txt';

if exist(plikOkt)
	printf('File %s already exists. \n',plikOkt);
	an=input('Overwrite? (Y/n)  ',"s");

	if an=='n'
		printf('Exiting generatorOktaw...\n');
		break;
	elseif an~='Y'
		printf('Unrecognized choice: %s\n',an);
		printf('Exiting generatorOktaw...\n');
		break;
	end;
end;

fid=fopen(plikOkt,'w');
skala=cell(length(okt),length(wys));
for m=1:length(okt)
	for k=1:length(wys)
		skala(m,k)=[wys{k},okt{m}];
		fprintf(fid,'%s ',char(skala(m,k)));
	end;
	fprintf(fid,'\n');
end;
fclose(fid);