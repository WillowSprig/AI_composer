function [sekw,przenies,kroki]=Z1_dzwieki_v8(rytm,ilTaktow,start,dol,gora,varargin)
%  ARGUMENTY:
%  rytm - sekwencja rytmiczna
%  ilTaktow - ilość taktów
%  start, dol, gora - struct('dzwiek',{},'znak',{},'oktawa',{}) - numeracja oktaw jak w MIDI
%  OPCJONALNIE:
%  pr - wektor prawdopodobieństw interwałów (od prymy do oktawy)
%  wlkInt - wariant wielkości interwałów (0 - tylko cz,m,w;	1 - KD cz/zmn/zw;	2 - wszystkie zmn/zw)
%  plik - plik txt ze skalą wyjściową (literowe nazwy dźwięków)

	if nargin==5
		pr=ones(1,14);
		wlkInt=0;
		plik='Cdiatoniczna.txt';
		przenies=1;
	elseif nargin==6
		pr=varargin{1};
		wlkInt=0;
		plik='Cdiatoniczna.txt';
		przenies=1;
	elseif nargin==7
		pr=varargin{1};
		wlkInt=varagin{2};
		plik='Cdiatoniczna.txt';
		przenies=1;
	elseif nargin==8
		pr=varargin{1};
		wlkInt=varagin{2};
		plik=varargin{3};
		przenies=1;
	elseif nargin==9
		pr=varargin{1};
		wlkInt=varargin{2};
		plik=varargin{3};
		przenies=varargin{3};
	else
		error('Nieprawidlowa liczba argumentow przy generowaniu przebiegu melodycznego: %d',nargin);
	end;
	
	fprintf('\tGenerowanie przebiegu melodycznego...\n');
%--------------------------------------------------------------------------------------------------------------------------------
	ilosc=length(find(rytm>0))-length(find(rytm==0));
	%jeśli początkowy i ostatni dźwięk są jednakowe
	if strcmp(dol.dzwiek,gora.dzwiek) && dol.oktawa==gora.oktawa
		warning('Ambitus rowny 0, tworzenie sekwencji rytmicznej o wysokosci diatonicznej %c%d',dol.dzwiek,dol.oktawa)
		zakresID=1;
		dzwiekTMP=dol.dzwiek;
		znakTMP=dol.znak;
		oktawaTMP=dol.oktawa;
		kierunekTMP=1;
		if dol.oktawa<=3
			przen=[1 zeros(1,ilosc-1)+4];
		elseif dol.oktawa>=6
			przen=[3 zeros(1,ilosc-1)+4];
		else
			przen=[2 zeros(1,ilosc-1)+4];
		end;
		sekw(ilosc)=struct('dzwiekID',{zakresID},'dzwiek',{start.dzwiek},'znak',{start.znak},'oktawa',{start.oktawa},'kierunek',{0});
		for k=1:ilosc
			sekw(k).dzwiekID=zakresID;
			sekw(k).dzwiek=dzwiekTMP;
			sekw(k).znak=znakTMP;
			sekw(k).oktawa=oktawaTMP;
			sekw(k).kierunek=kierunekTMP;
			sekw(k).przenosnik=przen(k);
		end;
		return;
	end;	%if (gora==dol)
%--------------------------------------------------------------------------------------------------------------------------------
	%jeśli jednak chcemy mieć jakąś melodię...
	poltony=[0 2 4 5 7 9 11 12];
	odleglosci=[2 2 1 2 2 2 1];
	oktMIN=dol.oktawa;
	oktMAX=gora.oktawa;
	Nokt=oktMAX-oktMIN+1;
	%wczytywanie skali materiałowej
	fid=fopen(plik,'r');
	tmp=textscan(fid,'%s');
	skala=deblank(cell2mat(tmp{:}));
	fclose(fid);
	wlkSkali=length(skala);
	%ograniczenie zakresu dźwięków
	wys=cell(wlkSkali,Nokt);
	for s=1:Nokt
        for k=1:wlkSkali
            wys{k,s}=strcat(skala(k),num2str(s+oktMIN-1));
        end;
	end;
	dolID=[find(strcmp(skala,dol.dzwiek)),dol.oktawa];
	goraID=[find(strcmp(skala,gora.dzwiek)),gora.oktawa];
	%przejście na indeksowanie liniowe
	dolID=dolID(1);
	goraID=size(wys,1)*(Nokt-1)+goraID(1);
	zakres=wys(dolID:goraID);
	
	%deklaracja sekwencji od dźwięku początkowego
	bgID=find(strcmp(zakres,[start.dzwiek,num2str(start.oktawa)]));
	sekw(ilosc)=struct('dzwiekID',{bgID},'dzwiek',{start.dzwiek},'znak',{start.znak},'oktawa',{start.oktawa},'kierunek',{0});
	sekw=fliplr(sekw);
	minID=bgID;
	maxID=bgID;	%najwyższy i najniższy to początkowo rozpoczynający...
%--------------------------------------------------------------------------------------------------------------------------------
	for k=2:ilosc
		poprzedni=sekw(k-1);
		%losowanie interwału ze sprawdzeniem poprawności
		[zakresID,dzwiekTMP,oktawaTMP,znakTMP,kierunekTMP,debugW]=F_losujInterwal_v4(poprzedni,skala,odleglosci,zakres,[dol.znak,gora.znak],poltony,wlkInt,pr);
		%przypisanie
		sekw(k).dzwiekID=zakresID;
		sekw(k).dzwiek=dzwiekTMP;
		sekw(k).znak=znakTMP;
		sekw(k).oktawa=oktawaTMP;
		sekw(k).kierunek=kierunekTMP;
		kroki(k-1,:)=debugW;		%DBG
		if zakresID<minID
			minID=zakresID;
		elseif zakresID>maxID
			maxID=zakresID;
		end;
	end;	%for k=2:ilosc
%--------------------------------------------------------------------------------------------------------------------------------
	%przenośniki oktawowe
	if przenies
		zakres=zakres(minID:maxID);
		t=1;
		m=1;
		takty=zeros(1,ilTaktow);
		%znajdowanie kresek taktowych
		for t=1:ilTaktow
			kreskaT=find(isnan(rytm(m:end)),1)+m-1;
			takty(t)=length(find(rytm(m:kreskaT)>0))-length(find(rytm(m:kreskaT)==0));
			m=kreskaT+1;
		end;
		[przen,przenies]=F_sprawdzKluczMS_v5(sekw,takty,skala,zakres);
	else
		przen=zeros(1,ilosc)+4;
	end;	%if przenies
	for k=1:ilosc
		sekw(k).przenosnik=przen(k);
	end;
end	%function