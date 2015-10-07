#/bin/tcsh -f

# If  layout is LVS clean, open the output file it gives and it should read PASS
# Else open the same file to see the errors and mismatches

set i=$1

/proj/gateway/layout/sr70/scripts/cds2cdlnetlist a0393831_kartik ${i} schematic ${i}.cdl

\mv ${i}.cdl /proj/gateway4/products/sr70/expts/a0393831/layout/oc1150bgfz

cd /proj/gateway4/products/sr70/expts/a0393831/layout/oc1150bgfz

/apps/ame/bin/pvkit verToHerc -cdlIn /proj/gateway4/products/sr70/expts/a0393831/layout/oc1150bgfz/${i}.cdl -technology c014p -cell ${i} -schematicTopCell ${i} -process C014.P8 P8

/apps/ame/bin/pvkit layToHerc -tech c014p -cell ${i} -layout /proj/gateway4/products/sr70/expts/a0393831/layout/oc1150bgfz/${i}.laff -process C014.P8 -metalSys 8M_5X1Y1Z

/apps/ame/bin/pvkit hercComp -tech c014p -cell ${i} -layout /proj/gateway4/products/sr70/expts/a0393831/layout/oc1150bgfz/${i}.laff -process C014.P8 -metalSys 8M_5X1Y1Z -property_tolerance 0.1 -explode_on_error true
