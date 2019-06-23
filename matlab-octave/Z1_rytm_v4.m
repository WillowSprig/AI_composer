function [tabl,belki]=Z1_rytm_v4(metrum,miara,dl,varargin)
%  ARGUMENTY:
%  metrum - liczba jednostek metrycznych w takcie
%  miara - jednostka metryczna
%  dl - liczba taktów
%  OPCJONALNIE:
%  pr - wektor prawdopodobieństw wystąpienia nowej wartości na kolejne miary w takcie
%  prPauz ~ 1-prawdopodobieństwo wystąpienia pauzy

	if nargin<4
		pr=repmat(.75,1,metrum).*3;
		prPauz=.35;
	elseif nargin==4
		pr=varargin{1}.*3;
		prPauz=.35;
	elseif nargin==5
		pr=varargin{1}.*3;
		prPauz=varargin{2};
	else
		error('Nieprawidlowa liczba argumentow przy generowaniu przebiegu rytmicznego: %d',nargin)
	end;
	if metrum~=length(pr)
		error('Dlugosc wektora prawdopodobienstw jest rozna od ilosci miar w takcie.')
	end;
	
	fprintf('\tGenerowanie przebiegu rytmicznego...\n');
%--------------------------------------------------------------------------------------------------------------------------------
	wartosc(metrum*16/miara*dl)=2;
	wartosc=fliplr(wartosc);
	
	%losowanie zmian wartosci rytmicznych 
	%z prawdopodobienstwem zaleznym od miary w takcie
	for k=2:length(wartosc)
		switch mod(k,metrum*16/miara)
			case 1
				wartosc(k)=round(rand()+pr(1));
			case 5
				wartosc(k)=round(rand()+pr(2));
			case 9
				wartosc(k)=round(rand()+pr(3));
			case 13
				wartosc(k)=round(rand()+pr(4));
			otherwise
				wartosc(k)=round(rand+prPauz);	
		end;	%switch
	end;	%for k=2:length(wartosc)
%--------------------------------------------------------------------------------------------------------------------------------
	%zamiana w. dodatnich na nuty i 0 na pauzy
	tabl=zeros(1,length(wartosc));
	n=1;
	if wartosc(1)
		tabl(n)=1;
	else
		tabl(n)=-1;
	end;
	
	for k=2:length(wartosc)
		if mod(k-1,metrum*16/miara)==0		%koniec taktu
			n=n+1;
			tabl(n)=NaN;
		end;
		if mod(k-1,16/miara)==0	%koniec grupy głównej
			n=n+1;
			if wartosc(k)==0	%pauza	
				tabl(n)=-1;	%zawsze nowa pauza
			elseif wartosc(k)>=2	%zmiana wartości
				tabl(n)=1;	%utwórz nową wartość
			elseif wartosc(k-1)==0	%przedłużenie wartości
					tabl(n)=1;	%poprzednia jest pauzą > nowa wartość
			else	%przedłużenie wartości
				tabl(n:n+1)=[0 1];	%poprzednia jest nutą > leguj
				n=n+1;
			end;
		else	%wewnątrz grupy głównej
			if wartosc(k)==0	%pauza
				if wartosc(k-1)==0
					tabl(n)=tabl(n)-1;	%poprzednia jest pauzą > przedłuż pauzę
				else
					n=n+1;		
					tabl(n)=-1;	%poprzednia jest nutą > nowa pauza
				end;
			elseif wartosc(k)>=2	%zmiana wartości
				n=n+1;
				tabl(n)=1;	%utwórz nową wartość
			else		%przedłużenie wartości
				if wartosc(k-1)==0	%pauza
					n=n+1;
					tabl(n)=1;	%poprzednia jest pauzą > nowa wartość
				else
					tabl(n)=tabl(n)+1;	%poprzednia jest nutą > przedłuż wartość
				end;
			end;
		end;	%sprawdzanie grup głównych
	end;	%for k=2:length(wartosc)
	tabl=tabl(1:n);
%--------------------------------------------------------------------------------------------------------------------------------	
	n=0;
	k=1;
	tablTMP=zeros(1,length(tabl));
	%poprawa czytelności i edytowalności
	while k<=length(tabl)
		n=n+1;
		if k<length(tabl) && tabl(k)==4 && tabl(k+1)==0 && tabl(k+2)==4	%legowane ćwierćnuty > półnuty		...co, jeśli warunek będzie spełniony na kresce taktowej?
			tablTMP(n)=8;
			k=k+2;
		elseif tabl(k)==5	%rytm łączony: 4 + 16
			tablTMP(n:n+2)=[4 0 1];
			n=n+2;
		elseif tabl(k)==-5	%rytm łączony: 4 + 16 - pauzy
			tablTMP(n:n+1)=[-4 -1];
			n=n+1;
		elseif tabl(k)==0 && isnan(tabl(k-1))
			tablTMP(n:n+1)=tabl([k k-1]);
			n=n+1;
		else	%"normalny" przypadek
			tablTMP(n)=tabl(k);
		end;
		k=k+1;
	end;	%while k<=length(tabl)
	tabl=[tablTMP(1:n) NaN];
	
	belki=zeros(1,length(tabl));
	if tabl(1)<4
		belki(1)=1;
		zacznij=0;
	else
		zacznij=1;
	end;
	licznik=tabl(1);
%--------------------------------------------------------------------------------------------------------------------------------
	%ustawianie wiązań w odpowiednich miejscach
	for k=2:length(belki)
		licznik=licznik+abs(tabl(k));
		if isnan(licznik)
			licznik=0;
			belki(k)=3;
			if tabl(k-1)<4
				belki(k-1)=2;
			end;
			zacznij=1;
		elseif mod(licznik,16/miara)==0
			if abs(tabl(k))<4 && tabl(k)~=0 && ~zacznij
				belki(k)=2;
				zacznij=1;
			end;
		else
			if abs(tabl(k))<4 && tabl(k)~=0 && zacznij
				belki(k)=1;
				zacznij=0;
			end;
		end;
	end;	%for k=2:length(belki)
	if find(belki==2,1)<find(belki==1,1)
		belki(find(belki==2,1))=0;
	end;	
end	%function