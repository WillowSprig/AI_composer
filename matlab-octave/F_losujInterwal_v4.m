function [dzwiekID,dzwiekTMP,oktawaTMP,znakTMP,kierunekTMP,debugW]=F_losujInterwal_v4(poprzedni,skala,odleglosci,zakres,znakiOgra,poltony,interwaly,pr)
%  poprzedni - struktura z parametrami poprzedniej wysokości (indeks dźwięku w wektorze skala, nazwa, oktawa, znak chrom.)
%  skala - self-explaining (tablica znaków, diatonicznie)
%  odleglosci - wektor odległości między kolejnymi stopniami skali (w półtonach, 1 - między 1 i 2, ostatni - między ost. a 1)
%  zakres - zestaw dźwięków, z którego losujemy (wys. diatoniczne z oktawami)
%  znakiOgra - [dol gora] - wartości znaku dla skrajnych dźwięków zakresu
%  poltony - odległości w półtonach między kolejnymi stopniami skali
%  interwaly - wariant wielkości interwałów (0 - tylko cz,m,w;	1 - KD cz/zmn/zw;	2 - wszystkie zmn/zw)
%  pr - wektor prawdopodobieństw interwałów (od 1)

	if nargin<8
		error('Losowanie interwalu - za malo argumentow: %d',nargin);
	elseif nargin>8
		error('Losowanie interwalu - za duzo argumentow: %d',nargin);
	end;
	
		switch interwaly
			case 0	%tylko czyste, małe i wlk.
				wlkIntD=0;
				prD=1;
				wlkIntN=[-1 0];
				prN=[.5 .5];
			case 1	%tylko kons. dosk. zmn i zw
				wlkIntD=[-1 0 1];
				prD=[.25 .5 .25];
				wlkIntN=[-1 0];
				prN=[.5 .5];
			case 2	%wszystkie zmn i zw
				wlkIntD=[-1 0 1];
				prD=[.25 .5 .25];
				wlkIntN=[-2 -1 0 1];
				prN=[.16 .32 .32 .2];
			otherwise
		end;
        wlkSkali=length(skala);
        skala=reshape(skala,1,wlkSkali);
		poprzedniID=strfind(skala,poprzedni.dzwiek);
		oktawaTMP=poprzedni.oktawa;
		znakTMP=poprzedni.znak;
		%prawdopodobieństwo zmiany kierunku - zależy od odległości od końców skali oraz od kierunku poprzedniego skoku
		%(bardziej prawdopodobny jest ruch do środka, ale zarazem przeciwny od poprzedniego kierunek)
		prKier=poprzedni.dzwiekID/length(zakres)*2.^poprzedni.kierunek;
		spr=0;		%zmienna semaforowa, sprawdza zgodność wyniku losowania z założeniami
%--------------------------------------------------------------------------------------------------------------------------------
		%losowanie interwału
		while ~spr	%losowanie z zakresu zadeklarowanej skali
			%liczba stopni do przejścia
			stopnieTMP=sum(rand()>cumsum(pr))+1;
			%wielkość interwału (m/w/cz itd.)		
			switch stopnieTMP
				case {1,4,5,8}
					wielkoscTMP=sum(rand()>cumsum(prD))-1;
				otherwise
					wielkoscTMP=sum(rand()>cumsum(prN))-1;
			end;
			wTMP=wielkoscTMP;	%DBG
			wielkoscTMP=wielkoscTMP+poltony(stopnieTMP);	%rozmiar interwału=liczba stopni skorygowana o wielkość interwału (0: czysty/wielki)
			%kierunek
			losKierunek=rand();
			if losKierunek>prKier
				kierunekTMP=1;
			else
				kierunekTMP=-1;
			end;
			nowyID=poprzedniID+kierunekTMP*(stopnieTMP-1);
			%prymy
			if nowyID==poprzedniID
				odlegloscTMP=znakTMP;
				znakTMP=znakTMP+kierunekTMP*wielkoscTMP;
			else
				if nowyID>wlkSkali || nowyID<=0
				%ewentualna zmiana oktawy
					oktawaTMP=oktawaTMP+kierunekTMP;
					nowyID=mod(nowyID,wlkSkali);
					if nowyID==0
						nowyID=wlkSkali;
					end;
					tmpID=sort([nowyID,poprzedniID]);

					odlegloscTMP=sum(odleglosci)-sum(odleglosci(tmpID(1):tmpID(2)-1))-kierunekTMP*znakTMP;	%zmiana oktawy > przewrót
				else
					tmpID=sort([nowyID,poprzedniID]);
					odlegloscTMP=sum(odleglosci(tmpID(1):tmpID(2)-1))-kierunekTMP*znakTMP;%suma półtonów między poprzednim a wylosowanym dźwiękiem - diatonicznie
				end;
				%dodanie znaku
				znakTMP=kierunekTMP*(wielkoscTMP-odlegloscTMP);
			end;	%if nowyID==poprzedniID
%--------------------------------------------------------------------------------------------------------------------------------
			%zamiana enharmoniczna
			while abs(znakTMP)>1
				enh=sign(znakTMP);
				enhID=nowyID+enh;
				if enhID==0
					enhID=wlkSkali;
					oktawaTMP=oktawaTMP-1;
					minID=enhID;
				elseif enhID==wlkSkali+1
					enhID=1;
					oktawaTMP=oktawaTMP+1;
					minID=wlkSkali;
				else
					minID=min([nowyID,enhID]);
				end;
				nowyID=enhID;
				znakTMP=znakTMP-enh*odleglosci(minID);
			end;	%while abs(znakTMP)>1
%--------------------------------------------------------------------------------------------------------------------------------
			dzwiekTMP=skala(nowyID);
			%sprawdzenie, czy wylosowano dźwięk z podanej skali
			dzwiekID=find(strcmp(zakres,[dzwiekTMP,num2str(oktawaTMP)]));
			if isempty(dzwiekID)
				dzwiekID=0;
			end;
			%dla skrajnych wysokości dodatkowy warunek na znak
			switch dzwiekID
				case 1
					if znakTMP>=znakiOgra(1)
						spr=1;
					else
						spr=0;
						oktawaTMP=poprzedni.oktawa;
						znakTMP=poprzedni.znak;
					end;
				case length(zakres)
					if znakTMP<=znakiOgra(2)
						spr=1;
					else
						spr=0;
						oktawaTMP=poprzedni.oktawa;
						znakTMP=poprzedni.znak;
					end;
				case 0	%powrót do poprzednich parametrów
					spr=0;
					oktawaTMP=poprzedni.oktawa;
					znakTMP=poprzedni.znak;
				otherwise
					spr=1;
			end;	%switch dzwiekID
		end;	%while ~spr
%--------------------------------------------------------------------------------------------------------------------------------
		if nargout==6
			debugW=[kierunekTMP*stopnieTMP wTMP wielkoscTMP odlegloscTMP];
		end;
end	%function