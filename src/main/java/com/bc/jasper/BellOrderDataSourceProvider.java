package com.bc.jasper;

import java.math.BigDecimal;
import java.text.DecimalFormat;
import java.text.NumberFormat;
import java.util.ArrayList;

import net.sf.jasperreports.engine.JRException;
import net.sf.jasperreports.engine.JRField;
import net.sf.jasperreports.engine.data.JRAbstractBeanDataSource;
import net.sourceforge.barbecue.Barcode;
import net.sourceforge.barbecue.BarcodeFactory;
import net.sourceforge.barbecue.BarcodeImageHandler;

import org.apache.log4j.Logger;

import com.bc.orm.BellOrder;
import com.bc.orm.BellOrderItem;
import com.bc.util.Money;

/**
 * Data source provider implementation that
 * provides a bean collection data source
 * containing instances of CustomerOrder class.
 */
public class BellOrderDataSourceProvider extends JRAbstractBeanDataSource {

    private static final Logger logger =
        Logger.getLogger("com.bc.util.BellOrderDataSourceProvider");

    private BellOrder order;
    private ArrayList<BellOrderItem> items;
    private BellOrderItem item;
    private NumberFormat nf = NumberFormat.getInstance();
    private boolean useShipped;
    private boolean none = false;
    private int count = 1;
    DecimalFormat percentFormat = new DecimalFormat("#0.##%");


    public BellOrderDataSourceProvider() {
        super(false);
    }

    public void moveFirst() throws JRException {
        // Nothing
    }

    public Object getFieldValue(JRField field) throws JRException {
        String name = field.getName();
        if (item == null){
            return "";
        }
        if (name.equals("counter")){
            return ""+count++;
        } else if (name.equals("orderedQuantity")){
            if (item.getQuantity() == null){
                return "0";
            }
            return item.getQuantity().toString();
        } else if (name.equals("shippedQuantity")){
            if (useShipped && item.getFilled() == null){
                return "0";
            } else if (!useShipped && item.getQuantity() == null){
                return "0";
            }
            if (useShipped) {
                return item.getFilled().toString();
            } else {
                return item.getQuantity().toString();
            }
        } else if (name.equals("backOrderedQuantity")){
            if (useShipped && item.getFilled() != null && item.getQuantity() != null) {
                if (item.getQuantity() > item.getFilled()){
                    return new Integer(item.getQuantity()-item.getFilled()).toString();
                }
            }
            return "0";
        } else if (name.equals("discount")){
            if (item.getDiscount() == null){
                return "0";
            }

            BigDecimal bd = new Money(item.getDiscount()).divide(new Money(100), BigDecimal.ROUND_HALF_UP);
            bd.setScale(2, BigDecimal.ROUND_HALF_UP);
            return percentFormat.format(bd.doubleValue());
            //return percentFormat.format(new Float(item.getDiscount()/100.0).doubleValue());
        } else if (name.equals("ISBN")){
            if (item.getDisplayIsbn() != null && item.getDisplayIsbn().length() > 0){
                return item.getDisplayIsbn();
            }
            return item.getIsbn();
        } else if (name.equals("condition")){
            return "";
        } else if (name.equals("title")){
            return item.getTitle();
        } else if (name.equals("bin")){
            if (item.getBin() == null){
                return "";
            }
            return item.getBin();
        } else if (name.equals("salePrice")){
            return "$"+nf.format(item.getPriceWithCredit());
        } else if (name.equals("extended")){
            if (useShipped && item.getExtended() == null){
                return "$"+nf.format(new Float(0));
            } else if (!useShipped && item.getTotalExtendedNonShipped() == null) {
                //logger.debug("getExtendedNonShipped == null");
                return "$"+nf.format(new Float(0));
            }
            if (useShipped){
                return "$"+nf.format(item.getTotalPrice());
            } else {
                //logger.debug("totalPriceNonShipped: "+item.getTotalPriceNonShippedWithCredit());
                return "$"+nf.format(item.getTotalPriceNonShipped());
            }
        } else if (name.equals("barcode")){
            if (item.getIsbn().length() == 10 || item.getIsbn().length() == 13){
                try {
                    Barcode barcode = BarcodeFactory.createCode128B(item.getIsbn());
                    barcode.setDrawingText(false);
                    //barcode.setFont(Font.decode("Dialog 14"));
                    barcode.setBarHeight(21);
                    barcode.setBarWidth(1);
                    return BarcodeImageHandler.getImage(barcode);
                } catch (Exception e){
                    // do nothing
                }
            }
        } else if (name.equals("listPrice")){
            // FIX
            //if (item.getInventoryItem() != null && item.getInventoryItem().getListPrice() != null){
            //    return "$"+nf.format(item.getInventoryItem().getListPrice());
            //}
            return "";
        }
        return null;
    }

    public boolean next() throws JRException {
        if (items.size() > 0){
            item = (BellOrderItem)items.remove(0);
            return true;
        }
        if (none){
            none = false;
            return true;
        }
        return false;
    }

    public void setup(BellOrder order, boolean useShipped) {
        setup(order, new ArrayList(order.getBellOrderItems()), useShipped);
    }

    public void setup(BellOrder order, ArrayList<BellOrderItem> items, boolean useShipped) {
        this.order = order;
        this.useShipped = useShipped;
        this.items = items;
        nf.setMaximumFractionDigits(2);
        nf.setMinimumFractionDigits(2);
        if (items.size() == 0){
            none = true;
        }
    }

}
