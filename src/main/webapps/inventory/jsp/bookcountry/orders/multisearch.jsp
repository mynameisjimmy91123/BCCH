<%@ include file="../../html-start.jspf" %>
<head>
<%@ include file="../../html-head.jspf" %>

<title>Book Country Inventory</title>

<jwr:script src="/bundles/orderBundle.js"/> 

<s:set name="stateSession" value="%{'order-search-state'}"/>
<%@ include file="../../statemanagement.jspf" %>

<script language="JavaScript" type="text/javascript">

var curSelectedIdx = null;
var curSelectedRec = null;
var curStart = 0;

Ext.onReady(function(){

    <s:set name="activeMenu" value="%{'orders'}"/>
    <%@ include file="../div-header-menu.jspf" %>

    var contentpanel = new Ext.Panel({
        id       : 'dualPanel',
        layout   : 'border',
        border   : false,
        bodyBorder: false,
        items : [
            {
               region: 'center',
               border   : false,
               bodyBorder: false,
               split:true,
               layout:'border',
               items: [
                   {    
                       region: 'center',
                       border   : false,
                       bodyBorder: false,
                       split:true,
                       type: 'xpanel',
                       layout: 'fit',
                       id: 'listpanel'
                   }, {    
                       region: 'north',
                       collapsible: true, plugins: [Ext.ux.PanelCollapsedTitle], 
                       split:true,
                       border   : false,
                       bodyBorder: false,
                       title: 'Order Search with Multiple Inventory ISBN',
                       iconCls: 'view_icon',
                       height:200,
                       minHeight: 80,
                       autoScroll: true,
                       type: 'xpanel',
                       layout: 'fit',
                       bodyCfg : {style: {'background':'#fbfbfb'}},
                       contentEl: 'searchpanel'
                   }                   
               ]
            },
            {
                region: 'east',
                title: 'Order Detail',
                layout   : 'fit',
                id: 'detailpanel',
                autoScroll: true,
                collapsible: true, plugins: [Ext.ux.PanelCollapsedTitle], 
                border   : false,
                bodyBorder: false,
                width:300,
                minWidth:150,
                split:true,
                html: noselectionhtml                
             }
        ]
    });


    new Ext.Viewport({
        id: 'mainviewport',
        layout: 'border',
        layoutConfig: {
            minWidth: 800,
            minHeight: 500
        },
        //bufferResize:true,
        items: [{
            region: 'north',
            id: 'northpanel',
            border: false,
            collapsible: false,
            layout: 'fit',
            height:60,
            margins: '0 0 0 0',
            cls: 'invtoolbar',
            bodyCfg : {style: {'border-bottom':'1px solid #999'} },
            items: [headermenu]
        },{
            region: 'center',
            margins: '0 0 0 0',
            collapsible: false,
            border: true,
            layout: 'fit',
            id: 'contentpanel',
            items: [contentpanel]
        },{
            region: 'south',
            margins: '0 0 0 0',
            collapsible: false,
            height: 24,
            border: true,
            bodyCfg : {style: {'background-color':'#ddd'} },
            id: 'footerpanel',
            layout: 'fit',
            contentEl: 'invfooter'
        }]
    });

    new Ext.Button({
        id:'ordersearchbutton', 
        applyTo:'orderSearchSubmit', 
        cls:"x-btn-text-icon", 
        icon:"/images/accept.png", 
        text:'Search', 
        disabled:false,
        handler: function(){
            document.getElementById("ordersearchform").submit();
        } 
    });
    
    setFocus("orderSearch-searchval0");
    
});
</script>

</head>
<body class="page">

<%@ include file="../div-header.jspf" %>

<div style="display:none">

<div id="searchpanel">
    <form class="formular" action="order!multiSearch.bc" id="ordersearchform" method="post">
        <table>
            <tr>
                <td align="right" valign="top">Multi ISBN: </td>
                <td style="padding-left:10px"><s:textarea name="search.multiIsbn" id="inventoryisbn" rows="8" cssStyle="width:200px;"/></td>
                <td style="padding-left:10px" valign="top">
                    <table>
                       <tr>
                        <td><s:checkbox name="selectAll" id="selectAll" onchange="javascript:selectAllForMultiSearch();"/></td>
                        <td style="padding-left:5px;"><label for="selectAll">Select All</label></td>
                        </tr>
                        <tr>
                        <td><s:checkbox name="search.includeBell" id="includeBell"/></td>
                        <td style="padding-left:5px;"><label for="includeBell">Include Bell Books</label></td>
                        </tr>
                        <tr>
                        <td><s:checkbox name="search.includeRestricted" id="includeRest"/></td>
                        <td style="padding-left:5px;"><label for="includeRest">Include Restricted</label></td>
                        </tr>
                        <tr>
                        <td><s:checkbox name="search.includeHigherEducation" id="includeHe"/></td>
                        <td style="padding-left:5px;"><label for="includeHe">Include HigherEducation</label></td>
                        </tr>
                    <tr><td><div style="height:20px;"></div></td></tr>
                    <tr>
                    <td></td>
                    <td><div id="orderSearchSubmit"></div></td>
                    </tr>
                    </table>
                </td>
            </tr>
        </table>
        <input type="submit" style="width: 0px; height: 0px; position: absolute; left: -50px; top: -50px;"/>
    </form>

</div>

<inv:table tableName="orders" sortable="true" exportable="true" tableTitle="Orders With Matching Inventory Items"
dataActionParams="search.includeBell=${search.includeBell},search.includeRestricted=${search.includeRestricted},search.includeHigherEducation=${search.includeHigherEducation}" 
dataActionProxyParam="search.multiIsbn" dataActionProxyParamValue="${search.multiIsbnEscaped}"
dataAction="order!multiSearchData.bc" table="${listTable}" addToContainer="listpanel" stateful="true"/>

</div>

<script language="JavaScript" type="text/javascript">
    Ext.onReady(function(){
        Ext.grid.ordersGrid.getSelectionModel().on('selectionchange', function(){
            setTimeout("updateOrderDetail()", 300);
        });
        Ext.grid.ordersGridDs.on('load', function(store, records, options){
            updateOrderDetail();
            if (options.params.start != curStart){
                curStart = options.params.start;
            } else if (curSelectedIdx != undefined){
                Ext.grid.ordersGrid.getSelectionModel().selectRow(curSelectedIdx);
                Ext.grid.ordersGrid.getView().focusRow(curSelectedIdx);
            }
        });
        Ext.grid.ordersGrid.getSelectionModel().on("rowselect", function(model, idx, rec){
            curSelectedIdx = idx;
            curSelectedRec = rec;
        });
    });
</script>

    
<%@ include file="../../div-footer.jspf" %>

</body>
</html>
