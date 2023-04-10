size = 4;

fd1 = fopen('../sim/behav/data/data1.txt', 'r');    %指向data文件的指针
fd2 = fopen('../sim/behav/data/data2.txt', 'r');
fd3 = fopen('../sim/behav/data/data3.txt', 'r');
fd4 = fopen('../sim/behav/data/data4.txt', 'r');

fw1 = fopen('../sim/behav/data/weight1.txt', 'r');  %指向weight文件的指针
fw2 = fopen('../sim/behav/data/weight2.txt', 'r');
fw3 = fopen('../sim/behav/data/weight3.txt', 'r');
fw4 = fopen('../sim/behav/data/weight4.txt', 'r');

fr = fopen('../sim/behav/data/result.txt', 'r');    %指向result文件的指针

data1 = fscanf(fd1, "%d%*[,;]", [size, size]);      %读取数组
data2 = fscanf(fd2, "%d%*[,;]", [size, size]);
data3 = fscanf(fd3, "%d%*[,;]", [size, size]);
data4 = fscanf(fd4, "%d%*[,;]", [size, size]);

data1 = data1.';                                    %将数组转置，方得到预期的顺序
data2 = data2.';
data3 = data3.';
data4 = data4.';

weight1 = fscanf(fw1, "%d%*[,;]", [3, 3]);
weight2 = fscanf(fw2, "%d%*[,;]", [3, 3]);
weight3 = fscanf(fw3, "%d%*[,;]", [3, 3]);
weight4 = fscanf(fw4, "%d%*[,;]", [3, 3]);

weight1 = weight1.';
weight2 = weight2.';
weight3 = weight3.';
weight4 = weight4.';

result_out = fscanf(fr, "%d%*[,;]", [size, size]);
result_out = result_out.';

fclose('all');

%开始卷积运算
result_expected = conv2(data1, rot90(weight1, 2), 'same') + conv2(data2, rot90(weight2, 2), 'same') ...
                + conv2(data3, rot90(weight3, 2), 'same') + conv2(data4, rot90(weight4, 2), 'same');
outcome = result_expected == result_out;

%打印结果
disp('result expected:');
disp(result_expected);
disp('result out:');
disp(result_expected);
disp('outcome:');
disp(outcome);
%disp('data:');
%disp([data1, nan(size,1), data2, nan(size,1), data3, nan(size,1), data4]);
%disp('weight:');
%disp([weight1, nan(3, 1), weight2, nan(3, 1), weight3, nan(3, 1), weight4]);

