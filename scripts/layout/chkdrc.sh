#/bin/tcsh -f

set i=$1

/apps/ame/bin/pvkit layoutConvert -technology c014p -outFormat gdsii \
	-layout /cdb/acd/sr70/sr70_io/cds/a0393831_kartik/ -cell ${i} \
	-outLayout /proj/gateway4/products/sr70/expts/a0393831/layout/oc1150bgfz/${i}.gds;

/apps/ame/bin/pvkit layoutConvert -technology c014p -outFormat laff \
	-layout /proj/gateway4/products/sr70/expts/a0393831/layout/oc1150bgfz/${i}.gds \
	-outLayout /proj/gateway4/products/sr70/expts/a0393831/layout/oc1150bgfz/${i}.laff;
	
/apps/ame/bin/pvkit runHerc -technology c014p -rules drc \
	-tool hercules -mode chip_sr70_8lm5x1y1zhp \
	-layout /proj/gateway4/products/sr70/expts/a0393831/layout/oc1150bgfz/${i}.laff -cell ${i};
