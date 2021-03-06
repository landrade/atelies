$             = require 'jquery'
Page          = require './seleniumPage'

module.exports = class AdminManageProductPage extends Page
  visit: (storeSlug, productId, cb) ->
    if typeof productId is 'string'
      super "admin/manageProduct/#{storeSlug}/#{productId}", cb
    else
      cb = productId
      super "admin/createProduct/#{storeSlug}", cb
       
  product: (cb) ->
    product =
      dimensions: {}
      shipping: dimensions: {}
    @parallel [
      => @getText "#editProduct #_id", (text) -> product._id = text
      => @getValue "#editProduct #name", (text) -> product.name = text
      => @getValue "#editProduct #price", (text) -> product.price = text
      => @getText "#editProduct #slug", (text) -> product.slug = text
      => @getSrc "#editProduct #showPicture", (text) -> product.picture = text
      => @getValue "#editProduct #tags", (text) -> product.tags = text
      => @getValue "#editProduct #description", (text) -> product.description = text
      => @getValue "#editProduct #height", (text) -> product.dimensions.height = parseInt text
      => @getValue "#editProduct #width", (text) -> product.dimensions.width = parseInt text
      => @getValue "#editProduct #depth", (text) -> product.dimensions.depth = parseInt text
      => @getValue "#editProduct #weight", (text) -> product.weight = parseFloat text
      => @getIsChecked "#editProduct #shippingDoesApply", (itIs) -> product.shipping.applies = itIs
      => @getIsChecked "#editProduct #shippingCharge", (itIs) -> product.shipping.charge = itIs
      => @getValue "#editProduct #shippingHeight", (text) -> product.shipping.dimensions.height = parseInt text
      => @getValue "#editProduct #shippingWidth", (text) -> product.shipping.dimensions.width = parseInt text
      => @getValue "#editProduct #shippingDepth", (text) -> product.shipping.dimensions.depth = parseInt text
      => @getValue "#editProduct #shippingWeight", (text) -> product.shipping.weight = parseFloat text
      => @getIsChecked "#editProduct #hasInventory", (itIs) -> product.hasInventory = itIs
      => @getValue "#editProduct #inventory", (text) -> product.inventory = parseInt text
    ], (-> cb(product))
  setFieldsAs: (product, cb) =>
    @type "#name", product.name
    @type "#price", product.price
    @type "#tags", product.tags?.join ","
    @type "#description", product.description
    @type "#height", product.dimensions?.height
    @type "#width", product.dimensions?.width
    @type "#depth", product.dimensions?.depth
    @type "#weight", product.weight
    if product.shipping?.applies
      if product.shipping?.charge then @check "#shippingCharge" else @uncheck '#shippingCharge'
      @type "#shippingHeight", product.shipping?.dimensions?.height
      @type "#shippingWidth", product.shipping?.dimensions?.width
      @type "#shippingDepth", product.shipping?.dimensions?.depth
      @type "#shippingWeight", product.shipping?.weight
    else
      @click '#shippingDoesNotApply'
    if product.hasInventory then @check "#hasInventory" else @uncheck '#hasInventory'
    @type "#inventory", product.inventory
    @eval "document.getElementById('inventory').blur()", cb
  clickUpdateProduct: (cb) => @pressButtonAndWait "#editProduct #updateProduct", cb
  clickDeleteProduct: (cb) => @pressButtonAndWait "#deleteProduct", cb
  clickConfirmDeleteProduct: (cb) => @eval "$('#confirmDeleteProduct').click()", cb
  setCategories: (categories, cb) =>
    @type "#categories", categories
    cb()
  setPictureFile: @::uploadFile.partial '#picture'
