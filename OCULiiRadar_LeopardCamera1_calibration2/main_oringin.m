%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%���ܣ�ʵ�����ϱ궨
%���룺
% data:�궨���ݾ��� N��5����NΪ��������������20��������ÿ��������ǰ��������ʾ�״�����[x,y,z]��float��������������ʾ��Ӧ��ͼ�������[xp,yp]��uint16��;
% A:�ڲξ��� 3��3����double float��
% B:��ξ��� 3��4����float��
%�����
% H:����ת�ƾ��� 3��4����double float��
%��غ�����
%psolution(alpha,fk,Jfk,Dk)��psolution(lambda,f,Jf,D)��p����С���˽�
%dphi = dphisolution(lambda,f,Jf,D)����dphi/dlambda
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%��ʼ��
clear all;
close all;
% ��ξ���������
x=[sym('thetax');sym('thetay');sym('thetaz');sym('tx');sym('ty');sym('tz')]; %���庯������ x����6��������x(1)~x(6)��double float��

% ��γ�ֵ�����úܹؼ���Ӱ�����Ƿ�����������
xk=[0;0;0;0;0;0];

% ������ξ���B
Rx=[1,0,0;0,cos(x(1)),sin(x(1));0,-sin(x(1)),cos(x(1))];
Ry=[cos(x(2)),0,-sin(x(2));0,1,0;sin(x(2)),0,cos(x(2))];
Rz=[cos(x(3)),-sin(x(3)),0;sin(x(3)),cos(x(3)),0;0,0,1];
B=[Rx*Ry*Rz,[x(4);x(5);x(6)]];
% �ڲξ���
A = [1984.70675623762,0,0;0,1985.52157573859,0;1462.83574464976,930.747160354737,1]'; % intrinsic matrix of LeopardCamera 2880x1860 oringin

%% ����������
data_xyz=readmatrix("./data/OCULiiRadar_points.xlsx", "Range", [1 1]);
load ./runs_oringin/imagePoints.mat
data(:, 1:3)=data_xyz(:, 1:3);
save ./runs_oringin/allPoints data

%% �Զ�+�ֶ��޳����õĵ�
data = data(data_xyz(:,4)==1,:);
data = data(sum(isnan(data),2)==0, :);
save ./runs_oringin/calibPoints data
%% 
N=size(data,1);%��ȡ���ݳ��ȣ�uint8��
H=A*B;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%�Ż���������
f=[];
for i=1:N%�����Ż���������
    % �����ǻ���
    Z=H*[data(i,1);data(i,2);data(i,3);1];
    % ���ǻ���
    %Zc = B*[data(i,1);data(i,2);data(i,3);1];  
    
    
    f=[f;data(i,4)-Z(1)/Z(3);data(i,5)-Z(2)/Z(3)];    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%L-M�㷨���֣����������Ż����⣬�Ż�����x��
Jf=jacobian(f);%���㺯���ſɱȾ���double float��
%��ʼ��
xk_ini=xk;%�Ż���������ֵ��double float��
fk=double(subs(f,x,xk));%f������ֵ��double float��
Jfk=double(subs(Jf,x,xk));%Jf������ֵ��double float��
Dk=sqrt(diag(diag(Jfk'*Jfk)));%Dk����ֵ��double float��
sigma=0.1;%sigma�������ã�float��
pk=1;%Pk����ֵ��double float��
deltak=0.1;%��������ֵ��float��
i=0;%ѭ��������uint16��
%loop
% while norm(pk)>0.1 %��һ�Ż���ֵ 
while i<200 %��ѭ������Ϊ�Ż���ֵ���Ż���ֵ���á�
    i=i+1%ѭ������ 
    %step a,����lambda��ţ�ٷ�Ȩ�ز���
    Jfkpinv=pinv(Jfk);%��α�棨double float��
    if norm(Dk*pinv(Jfk)*fk)<=(1+sigma)*deltak%�ж��½��ݶ�
        %�ݶ�ƽ�ȣ����Խ���
        lambdak=0;%��double float��
        pk=-pinv(Jfk)*fk;%�仯��pk��double float��
    else
        %�ݶȹ�����ţ�ٷ����
        alpha=0;%lambda�Ż���ֵ��double float��
        u=norm((Jfk*inv(Dk))'*fk)/deltak;%��ȷ����㣨double float��
        palpha=psolution(alpha,fk,Jfk,Dk);%p_alpha����(double float��
        qalpha=Dk*palpha;%q_alpha����(double float��
        phi=norm(qalpha)-deltak;%phi����(double float��
        dphi = dphisolution(alpha,fk,Jfk,Dk);%dphi/dlambda����(double float��
        l=-phi/dphi;%��ȷ�����(double float��
        j=0;%ѭ����ʼ����uint16��
        while (abs(phi)>sigma*deltak)&&(j<100)%lambda�Ż�ѭ��
            j=j+1;%ѭ������
            if alpha<=l||alpha>=u%�ж��Ƿ񳬹�ȡֵ��Χ
                alpha=(0.001*u>sqrt(l*u))*0.001*u+(0.001*u<=sqrt(l*u))*sqrt(l*u);%����ʱ���Ż�����alpha���е���
            end
            if phi<0%�ж��Ƿ��½�����
                u=alpha;%��ȷ�����
            end
            l=l*(l>(alpha-phi/dphi))+(alpha-phi/dphi)*(l<=(alpha-phi/dphi));%��ȷ�����
            alpha=alpha-(phi+deltak)/deltak*phi/dphi;%alpha����
            palpha=psolution(alpha,fk,Jfk,Dk);%p_alpha����
            qalpha=Dk*palpha;%q_alpha����
            phi=norm(qalpha)-deltak;%phi����
            dphi=dphisolution(alpha,fk,Jfk,Dk);%dphi/dlambda����
        end
        lambdak=alpha;%�Ż���ɣ�lambda��ֵ
        pk = psolution(lambdak,fk,Jfk,Dk);%pk����
    end
    %step b���������������Զȼ���
    fkp=double(subs(f,x,xk+pk));%�仯���Ż�����ȡֵ(double float��
    fkkp(:,i)=fkp'*fkp;
    rhok=((fk'*fk)-fkp'*fkp)/(fk'*fk-(fk+Jfk*pk)'*(fk+Jfk*pk)) ;%���Զȼ���(double float��
    %step c���Ż���������
    if rhok>0.0001%���ԶȺ���
        xk=xk+pk;%�Ż���������
        fk=double(subs(f,x,xk));%fk����
        Jfk=double(subs(Jf,x,xk)); %Jfk����
    end
    %step d����������
    if rhok<=0.25%���Զȹ�С��˵����������
        deltak=0.5*deltak;%������С����
    elseif (rhok>0.25&&rhok<0.75&&lambdak==0)||rhok>=0.75%���Զȹ���˵��������С
        deltak=2*norm(Dk*pk);%�����������
    end
    %step e�����²����ݶ�
    Dk=(Dk>sqrt(diag(diag(Jfk'*Jfk)))).*Dk+(Dk<=sqrt(diag(diag(Jfk'*Jfk)))).*sqrt(diag(diag(Jfk'*Jfk)));%����Dk
    xkk(:,i)=xk;%�Ż������������洢��12��I����IΪ�Ż�ѭ������ĿǰΪ1000����
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%��ͼ����
xkk_ini=xk_ini*ones(1,size(xkk,2));%�������ȼ��������þ����㣨12��I����double float��
y=diag(sqrt((xkk-xkk_ini)'*(xkk-xkk_ini)));%�������ȼ��㣬������double float��
plot(y)%��ͼ
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%�����洢
Hx=double(subs(H,x,xk));%����ת�ƾ���4��3����double float��
Bx=A\Hx;
save ./runs_oringin/Hx Hx;%����ת�ƾ���洢���������
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

