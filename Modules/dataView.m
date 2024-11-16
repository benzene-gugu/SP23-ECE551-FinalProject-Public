filename = 'tone_hex_lft.txt';
q = quantizer('fixed','nearest','saturate',[16 0]);
FID = fopen(filename);
datafromfile = textscan(FID,'%s');
datafromfile = datafromfile{1};
decData = hex2num(q,datafromfile);
decData = cell2mat(decData);
fclose(FID);
leftData = decData;
filename = 'tone_hex_rght.txt';
q = quantizer('fixed','nearest','saturate',[16 0]);
FID = fopen(filename);
datafromfile = textscan(FID,'%s');
datafromfile = datafromfile{1};
decData = hex2num(q,datafromfile);
decData = cell2mat(decData);
fclose(FID);
rightData = decData;

plot(abs(fft(leftData-rightData)));

%{
t=1/44100;
x=0:t:t*(length(binleft)-1);
plot(x,binleft);
xlim([0 0.01]);
%}