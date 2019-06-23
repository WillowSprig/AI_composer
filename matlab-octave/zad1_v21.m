clear all
clc

start=0;
fprintf('\nUzyc parametrow domyslnych, zdefiniowanych w skrypcie?\n')
while ~start
	odp=input('T/n ','s');
	if strcmp(odp,'n')
		start=2;
	elseif strcmp(odp,'T')
		start=1;
	else
		start=0;
	end;
end;

%parametry wejściowe
switch start
	case 2
		[metrum,ileTaktow,dzwIn,prInt,wlkInt]=zad1CLI();
		humilis=dzwIn(1);
		altus=dzwIn(2);
		primus=dzwIn(3);
		miara=4;	%jednostka metryczna
		prRytm=[.75 .2 .4 .15 .6 .3 .5 .1];	%prawdopodobieństwa wystąpienia nowej wartości na kolejną miarę w takcie
		prRytm=prRytm(1:metrum);
	case 1
		%rytmika
		metrum=4;	%liczba jendostek w takcie
		miara=4;	%jednostka metryczna
		ileTaktow=15;	%liczba taktów
		prRytm=[.75 .2 .3 .15];	%prawdopodobieństwa wystąpienia nowej wartości na kolejną miarę w takcie
		%melodyka
		%numeracja oktaw - w zależności od zadeklarowanej najniższej (zmienna okt poniżej); domyślnie: jak w MIDI
		humilis=struct('dzwiek',{'d'},'znak',{-1},'oktawa',{4});		%najniższy dźwięk
		altus=struct('dzwiek',{'b'},'znak',{1},'oktawa',{7});		%najwyższy dźwięk
		primus=struct('dzwiek',{'f'},'znak',{0},'oktawa',{4});		%dźwięk początkowy
		prInt=[.08 .17 .2 .2 .17 .06 .05 .07 ];	%prawdopodobieństwa interwałów (od prymy włącznie)
		wlkInt=2;	%0 - tylko cz,m,w;	1 - KD cz/zmn/zw;	2 - wszystkie zmn/zw
	otherwise
		error('Bledna wartosc zmiennej start: ',start);
end;	%switch start
%********************************************************************************************************************************
%--------------------------------------------------------------------------------------------------------------------------------
system('cls');
if strfind([humilis.dzwiek,altus.dzwiek,primus.dzwiek],'h')
	error('Nierozpoznana wysokosc. W notacji angielskiej h=b');
end;
if sum(prInt)<1-1e-5 || sum(prInt)>1+1e-5
	warning('Suma prawdopodobienstw interwalow = %.2f jest rozna od 1!',sum(prInt));
end;
if sum(prRytm)<1-1e-5 || sum(prRytm)>1+1e-5
	warning('Suma prawdopodobienstw rytmicznych = %.2f jest rozna od 1!',sum(prRytm));
	fprintf('...ale na razie tak jest dobrze...\n\n');
end;
%zapis
przen=1;	%0 - stały klucz;	1 - dopasuj klucz
wysSRC='Cdiatoniczna.txt';
tonacja='c';
tryb='\major';
wartosci={'16';'8';'8.';'4';'';'4.';'4..';'2'};
belka={'[',']',' |\n\t'};
okt={',,',',','',char(39),repmat(char(39),1,2),repmat(char(39),1,3),repmat(char(39),1,4)};
chromatyka={'es','','is'};
przenOkt={'\\clef bass\n\t','\\clef treble\n\t','\\clef "treble^8"\n\t',''};
intInfo={'"uczen" -- czyste, male, wielkie','"kompozytor" -- KD czyste, zmniejszone i zwiekszone; KN i D male, wielkie','"kompozytor wspolczesny" -- czyste, male, wielkie, zmniejszone, zwiekszone'};

%--------------------------------------------------------------------------------------------------------------------------------
fprintf('\n\t*\tParametry wejsciowe\t*\n');
fprintf('\tMetrum: %d/4\n\tLiczba taktow: %d\n',metrum,ileTaktow);
fprintf('\n\tDolny dzwiek graniczny: %s%d\n',[humilis.dzwiek,chromatyka{humilis.znak+2}],humilis.oktawa);
fprintf('\tGorny dzwiek graniczny: %s%d\n',[altus.dzwiek,chromatyka{altus.znak+2}],altus.oktawa);
fprintf('\tDzwiek rozpoczynajacy: %s%d\n',[primus.dzwiek,chromatyka{primus.znak+2}],primus.oktawa);
fprintf('\n\tWariant interwalow:\n\t%s\n',intInfo{wlkInt+1});
fprintf('\n\tPrawdopodobienstwa interwalow: ');
fprintf('%.2f ',prInt);
fprintf('\n\n\t*\t*\t*\t*\t*\t*\t*\t*\t*\n\n');
%********************************************************************************************************************************
%--------------------------------------------------------------------------------------------------------------------------------
%generowanie losowej melodii
dzwieki=struct('dzwiekID',{},'dzwiek',{},'znak',{},'oktawa',{},'kierunek',{});
[rytm,belkowanie]=Z1_rytm_v4(metrum,miara,ileTaktow,prRytm);
liczbaDzwiekow=length(find(rytm>0))-length(find(rytm==0));
[dzwieki,przen,kroki]=Z1_dzwieki_v8(rytm,ileTaktow,primus,humilis,altus,prInt,wlkInt,wysSRC,przen);
%--------------------------------------------------------------------------------------------------------------------------------
%********************************************************************************************************************************
%sklejanie wartosci rytmicznych i wysokosci
fprintf('\tTworzenie zapisu nutowego...\n');
%--------------------------------------------------------------------------------------------------------------------------------
m=1;
d=1;
sekwencja{length(rytm)}=[' ',dzwieki(d).dzwiek, chromatyka{dzwieki(d).znak+2}, okt{dzwieki(d).oktawa}, wartosci{rytm(m)}];
sekwencja=fliplr(sekwencja);
if belkowanie(m)
	sekwencja{m}=[sekwencja{m} belka{belkowanie(m)}];
end;
sekwencja{m}=[przenOkt{dzwieki(d).przenosnik} sekwencja{m}];
przenosnikPoprz=dzwieki(d).przenosnik;

for m=2:length(sekwencja)
	if isnan(rytm(m))
		sekwencja{m}='';
	elseif rytm(m)==0	%ligatura
		sekwencja{m}='~';
	elseif rytm(m)<0		%pauzy
		sekwencja{m}=[' r',wartosci{abs(rytm(m))}];
	elseif rytm(m)>0		%dźwięki
		if rytm(m-1)==0	%po ligaturze - przedłużenie poprzedniej wartości
			sekwencja{m}=[' ',dzwieki(d).dzwiek, chromatyka{dzwieki(d).znak+2}, okt{dzwieki(d).oktawa}, wartosci{rytm(m)}];
		else
			d=d+1;
			sekwencja{m}=[' ',dzwieki(d).dzwiek, chromatyka{dzwieki(d).znak+2}, okt{dzwieki(d).oktawa}, wartosci{rytm(m)}];
		end;
	end;
	if belkowanie(m)
		sekwencja{m}=[sekwencja{m} belka{belkowanie(m)}];
	end;
	if dzwieki(d).przenosnik~=przenosnikPoprz
		sekwencja{m}=[przenOkt{dzwieki(d).przenosnik} sekwencja{m}];
		przenosnikPoprz=dzwieki(d).przenosnik;
	end;
end;
%--------------------------------------------------------------------------------------------------------------------------------
% zapis do .ly
fprintf('\tZapis do pliku .ly\n');
%--------------------------------------------------------------------------------------------------------------------------------
fname='Pseudolosowosc.ly';
fid=fopen(fname,'w');
fprintf(fid,'\\version "2.18.2"\n');
fprintf(fid,'\\score{\n')
fprintf(fid,'\\absolute\n');
fprintf(fid,'{\n\\key %c %s \n',tonacja, tryb);
fprintf(fid,'\\time %d/%d\n',metrum,miara);
fprintf(fid,'\\autoBeamOff\n\\set strictBeatBeaming = ##t\n');
fprintf(fid,'\\set Score.barNumberVisibility = #(every-nth-bar-number-visible 2)\n');
%  fprintf(fid,'\\set Score.barNumberVisibility = #all-bar-numbers-visible\n');
fprintf(fid,'\\override Score.BarNumber.break-visibility = ##(#f #t #t)\n');
fprintf(fid,'\t\\bar ""\n\t');
for m=1:length(sekwencja)
	fprintf(fid,sekwencja{m});
end;
fprintf(fid,'\\bar "||"\n}\n');
fprintf(fid,'\\layout {')
if ~przen
	fprintf(fid,'\\context {\\Voice \\consists "Ambitus_engraver"}');
end;
fprintf(fid,'}\n\\midi{\\tempo 4 = 76}\n')
fprintf(fid,'}');
fclose(fid);
%--------------------------------------------------------------------------------------------------------------------------------
%kompilacja
fprintf('\tKompilacja...\n\n\n');
kom=['lilypond ',fname];
%  kom=['"D:\Program Files (x86)\LilyPond\usr\bin\lilypond.exe" ',fname];
system(kom);
%--------------------------------------------------------------------------------------------------------------------------------
%  %wersja png - opcjonalnie
%  kom=['lilypond --png ',fname];
%  system(kom);
%  im=imread([fname(1:end-3),'.png']);
%  imshow(im);