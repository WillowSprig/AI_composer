function [metrum,dl,dzwIn,prInt,wlkInt]=zad1UI()

	system('clear');
	fprintf('\n\t*\tRytm\t*\n');
	try
		metrum=input('Podaj liczbe cwiercnut w takcie: >');
	catch
		metrum=input('Blad wprowadzania, druga szansa: > ');
	end;
	if metrum<=0 || metrum>8
		try
			metrum=input('Bledna wartosc. Podaj liczbe cwiercnut w takcie: >');
		catch
			metrum=input('Blad wprowadzania, druga szansa: > ');
		end;
	end;
	
	spr=0;
	while ~spr
		try
			dl=input('Podaj liczbe taktow do wygenerowania: >');
		catch
			dl=input('Blad wprowadzania, druga szansa: > ');
		end;
		if dl>500
			fprintf('To moze chwile potrwac... Czy jestes pewien, ze potrzebujesz az tylu taktow?\n');
			odp=input('T/n ','s');
				if strcmp(odp,'T')
					spr=1;
				elseif strcmp(odp,'n')
					try
						dl=input('Podaj liczbe taktow do wygenerowania: >');
					catch
						dl=input('Blad wprowadzania, druga szansa: > ');
					end;
				end;
		elseif dl<=0
			try
				dl=input('Bledna wartosc. Podaj liczbe taktow do wygenerowania: >');
			catch
				dl=input('Blad wprowadzania, druga szansa: > ');
			end;
		else
			spr=1;
		end;
	end;
	fprintf('\n\t*\tDzwieki\t*\n\t<nazwa literowa><oktawa(zgodnie z MIDI)>\n\n')
	dzwIn=struct('dzwiek',{},'znak',{},'oktawa',{});
	dzwInfo={'Podaj najnizszy dzwiek';'Podaj najwyzszy dzwiek';'Podaj dzwiek rozpoczynajacy'};
	for k=1:3
		spr=0;
		while ~spr
			fprintf(dzwInfo{k});
			dzwTMP=input(':> ','s');
			if length(dzwTMP)>4 || length(dzwTMP)<2 || length(dzwTMP)==3
				fprintf('Nieprawidlowy zapis dzwieku\n');
				spr=0;
			else
				if isempty(strfind('cdefgab',dzwTMP(1)))
					fprintf('Nierozpoznana wysokosc dzwieku\n');
					spr=0;
				else
					dzwIn(k).dzwiek=dzwTMP(1);
					spr=1;
				end;
				switch length(dzwTMP)
					case 4
						dzw(k).oktawa=str2num(dzwTMP(4));
						if strcmp(dzwTMP(2:3),'is')
							dzwIn(k).znak=1;
						elseif strcmp(dzwTMP(2:3),'es')
							dzwIn(k).znak=-1;
						else
							fprintf('Nierozpoznana wysokosc dzwieku\n');
							spr=0;
						end;
					case 2
						dzwIn(k).oktawa=str2num(dzwTMP(2));
						dzwIn(k).znak=0;
				end;	%switch length(dzwTMP)
			end;	%sprawdzanie długości ciągu z nazwą dźwięku
		end;	%while ~spr
	end;

	prInt=zeros(1,8);
	intInfo={'pryma','sekunda','tercja','kwarta','kwinta','seksta','septyma','oktawa'};
	fprintf('\n\t*\tInterwaly\t*\n');
	fprintf('Podaj prawdopodobienstwa wystapienia interwalow (0-1)\n');
	k=1;
	while k<=8
		try
			fprintf(intInfo{k});
			prInt(k)=input(': > ');
		catch
			fprintf('Blad wprowadzania, druga szansa - %s',intInfo{k});
			prInt(k)=input(': > ');
		end;
		if prInt(k)>=1
			fprintf('Prawdopodobienstwo >=1, czy jestes pewien?\t')
			odp=input('T/n ','s');
			if strcmp(odp,'T')
				k=k+1;
			end;
		else
			k=k+1;
		end;
	end;	%while k<=8
	
	fprintf('Wybierz wariant wielkosci interwalow\n0 - cz, m, w\n1 - cz/zm/zw, m, w\n2 - cz/zm/zw, m/zm/zw, w/zm/zw\n')
	try
		wlkInt=input(': > ');
	catch
		wlkInt=input('Blad wprowadzania, druga szansa: > ');
	end;
end	%function