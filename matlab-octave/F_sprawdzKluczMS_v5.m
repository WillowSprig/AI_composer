function [przenosnik,zmiany]=F_sprawdzKluczMS_v5(sekw,takty,skala,zakres)
%  sekw - sekwencja wysokości do sprawdzenia
%  takty - ilość dźwięków w każdym takcie
%  skala - self-explaining (tablica znaków, diatonicznie)
%  zakres - wylosowanych dźwięków (wys. diatoniczne z oktawami) - 
		%niekoniecznie wszystkie z niego występują, ale wszystkie wylosowane się w nim mieszczą
		%oraz na pewno występują najwyższy i najniższy
	
	if nargin<4
		error('Sprawdzanie kluczy - za malo argumentow: %d',nargin);
	elseif nargin>4
		error('Sprawdzanie kluczy - za duzo argumentow: %d',nargin);
	end;
%--------------------------------------------------------------------------------------------------------------------------------	
	%od ilu dźwięków "niewygodnych w zapisie" następuje zmiana
	prog=4;
	%o ile stopni dźwięki mogą wychodzić poza zakres klucza
	tolerancja=2;
	%dźwięki graniczne
	granice=['f3';'d4';'a5';'d6'];
	dlZakresu=length(zakres);
	skala=reshape(skala,1,length(skala));
	%ustalanie granic zmiany kluczy względem granic zakresu wylosowanych dźwięków
	for g=1:size(granice,1)
		grID=find(strcmp(zakres,granice(g,:)));
		if isempty(grID)
			minDz=zakres{1};
			maxDz=zakres{end};
			dzw=strfind(skala,granice(g,1));
			okt=str2num(granice(g,2));
			if (dzw<=strfind(skala,minDz(1)) && okt==str2num(minDz(2))) || okt<str2num(minDz(2))
				graniceID(g)=1;
			elseif (dzw>=strfind(skala,maxDz(1)) && okt==str2num(maxDz(2))) || okt>str2num(maxDz(2))
				graniceID(g)=dlZakresu;
			end;
		else
			graniceID(g)=grID;
		end;
	end;	%for g=1:length(granice)
	ilosc=length(sekw);
	przenosnik=zeros(1,ilosc)+4;
%--------------------------------------------------------------------------------------------------------------------------------
	%wszystkie wysokości mieszczą się w zakresie któregoś klucza > wyjście z funkcji
	if graniceID(1)<tolerancja && graniceID(3)>dlZakresu-tolerancja
		przenosnik(1)=2;
		zmiany=0;
		return;
	elseif graniceID(1)>dlZakresu-tolerancja
		przenosnik(1)=1;
		zmiany=0;
		return;
	elseif graniceID(3)<tolerancja
		przenosnik(1)=3;
		zmiany=0;
		return;
	end;
%--------------------------------------------------------------------------------------------------------------------------------
	%trzeba sprawdzać
	for k=1:ilosc
		dzwiekID(k)=find(strcmp(zakres,[sekw(k).dzwiek,num2str(sekw(k).oktawa)]));
	end;
	ilTaktow=length(takty);
	k=1;
	licznik=[0 0 0];
	klucz=zeros(1,ilTaktow);
	
	%sprawdzanie w każdym takcie
	for t=1:ilTaktow
		dlTaktu=takty(t);
		nowyTakt(t)=k;
		takt=dzwiekID(k:k+dlTaktu-1);
		minTakt(t)=min(takt);
		maxTakt(t)=max(takt);
		licznik(:)=[length(find(takt<=graniceID(2)+tolerancja))...	%liczba dźwięków w basowym
			length(find(takt<=graniceID(4)))-length(find(takt<graniceID(1)))...	%liczba dźwięków w wiolinowym
			length(find(takt>=graniceID(3)-tolerancja))];	%liczba dźwięków w wiolinowym 8va
		%dopasowywanie klucza
		[licznikTMP,kluczTMP]=max(licznik);
%  		fprintf('Takt: %d\tlicznik: %d %d %d\tmax: %d\tklucz: %d\n',t,licznik,licznikTMP,kluczTMP);	%DBG
		if length(find(licznik==licznikTMP))>1
			przenosnik(k)=2;
		else
			przenosnik(k)=kluczTMP;
		end;
		k=k+dlTaktu;
	end;	%for m=1:length(takty)
%--------------------------------------------------------------------------------------------------------------------------------
	%wyszukiwanie pojedynczych kluczy i ewentualna zamiana
	if ilTaktow-length(find(klucz==2))==1
		t=find(klucz~=2);
		if minTakt(t)>=graniceID(1)-tolerancja && maxTakt(t)<=graniceID(4)+tolerancja
			przenosnik(nowyTakt(t))=2;
		end;
	elseif ilTaktow-length(find(klucz==1))==1
		t=find(klucz~=1);
		if maxTakt(t)<=graniceID(2)+tolerancja
			przenosnik(nowyTakt(t))=1;
		end;
	elseif ilTaktow-length(find(klucz==3))==1
		t=find(klucz~=3);
		if minTakt(t)>=graniceID(3)-tolerancja
			przenosnik(nowyTakt(t))=3;
		end;
	end;
	%usuwanie powtórek
	poprzedni=przenosnik(1);
	for t=2:ilTaktow
		if przenosnik(nowyTakt(t))==poprzedni
			przenosnik(nowyTakt(t))=4;
		else
			poprzedni=przenosnik(nowyTakt(t));
		end;
	end;
	%%%
	if length(find(przenosnik~=4))==1
		zmiany=0;
	else
		zmiany=1;
	end;
end	%function