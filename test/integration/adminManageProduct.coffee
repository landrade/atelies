require './support/_specHelper'
Store                       = require '../../app/models/store'
Product                     = require '../../app/models/product'
User                        = require '../../app/models/user'
AdminManageProductPage      = require './support/pages/adminManageProductPage'
AmazonFileUploader          = require '../../app/helpers/amazonFileUploader'
path                        = require "path"

describe 'Admin Manage Product page', ->
  page = product = product2 = store = userSeller = null
  before (done) ->
    page = new AdminManageProductPage()
    cleanDB (error) ->
      return done error if error
      whenServerLoaded ->
        store = generator.store.a()
        store.save()
        product = generator.product.a()
        product.save()
        product2 = generator.product.d()
        product2.save()
        userSeller = generator.user.c()
        userSeller.stores.push store
        userSeller.save()
        done()
  after (done) -> page.closeBrowser done
  describe 'viewing product', ->
    before (done) ->
      page.loginFor userSeller._id, ->
        page.visit store.slug, product._id.toString(), done
    it 'shows product', (done) ->
      page.product (aproduct) ->
        aproduct._id.should.equal product._id.toString()
        aproduct.name.should.equal product.name
        aproduct.price.should.equal product.price.toString()
        aproduct.slug.should.equal product.slug
        aproduct.picture.should.equal product.picture
        aproduct.tags.should.equal product.tags.join ','
        aproduct.description.should.equal product.description
        aproduct.dimensions.height.should.equal product.dimensions.height
        aproduct.dimensions.width.should.equal product.dimensions.width
        aproduct.dimensions.depth.should.equal product.dimensions.depth
        aproduct.weight.should.equal product.weight
        aproduct.shipping.applies.should.equal product.shipping.applies
        aproduct.shipping.charge.should.equal product.shipping.charge
        aproduct.shipping.dimensions.height.should.equal product.shipping.dimensions.height
        aproduct.shipping.dimensions.width.should.equal product.shipping.dimensions.width
        aproduct.shipping.dimensions.depth.should.equal product.shipping.dimensions.depth
        aproduct.shipping.weight.should.equal product.shipping.weight
        aproduct.hasInventory.should.equal product.hasInventory
        aproduct.inventory.should.equal product.inventory
        done()

  describe "can't update invalid product", ->
    before (done) ->
      page.loginFor userSeller._id, ->
        page.visit store.slug, product._id.toString(), ->
          page.setFieldsAs {name:'', price:'', tags:[], description:'', dimensions: {height:'dd', width: 'ee', depth:'ff'}, weight: 'gg', shipping: { applies: true, dimensions: {height:'edd', width: 'eee', depth:'eff'}, weight: 'egg'}, inventory: 'hh'}, ->
            page.clickUpdateProduct done
    it 'is at the product manage page', (done) ->
      page.currentUrl (url) ->
        url.should.equal "http://localhost:8000/admin/manageProduct/#{product.storeSlug}/#{product._id}"
        done()
    it 'did not update the product', (done) ->
      Product.findById product._id, (err, productOnDb) ->
        return done err if err
        productOnDb.name.should.equal product.name
        productOnDb.price.should.equal product.price
        productOnDb.picture.should.equal product.picture
        productOnDb.tags.should.be.like product.tags
        productOnDb.description.should.equal product.description
        productOnDb.dimensions.height.should.equal product.dimensions.height
        productOnDb.dimensions.width.should.equal product.dimensions.width
        productOnDb.dimensions.depth.should.equal product.dimensions.depth
        productOnDb.weight.should.equal product.weight
        productOnDb.shipping.applies.should.equal product.shipping.applies
        productOnDb.shipping.charge.should.equal product.shipping.charge
        productOnDb.shipping.dimensions.height.should.equal product.shipping.dimensions.height
        productOnDb.shipping.dimensions.width.should.equal product.shipping.dimensions.width
        productOnDb.shipping.dimensions.depth.should.equal product.shipping.dimensions.depth
        productOnDb.shipping.weight.should.equal product.shipping.weight
        productOnDb.hasInventory.should.equal product.hasInventory
        productOnDb.inventory.should.equal product.inventory
        done()
    it 'shows error messages', (done) ->
      page.errorMessagesIn '#editProduct', (errorMsgs) ->
        errorMsgs.name.should.equal 'O nome é obrigatório.'
        errorMsgs.price.should.equal 'O preço é obrigatório.'
        errorMsgs.height.should.equal 'A altura deve ser um número.'
        errorMsgs.width.should.equal 'A largura deve ser um número.'
        errorMsgs.depth.should.equal 'A profundidade deve ser um número.'
        errorMsgs.weight.should.equal 'O peso deve ser um número.'
        errorMsgs.shippingHeight.should.equal 'A altura deve ser um número entre 2 e 105.'
        errorMsgs.shippingWidth.should.equal 'A largura deve ser um número entre 11 e 105.'
        errorMsgs.shippingDepth.should.equal 'A profundidade deve ser um número entre 16 e 105.'
        errorMsgs.shippingWeight.should.equal 'O peso deve ser um número entre 0 e 30.'
        errorMsgs.inventory.should.equal 'O estoque deve ser um número.'
        done()

  describe "can't delete shipping info on a product that will be posted", ->
    before (done) ->
      page.loginFor userSeller._id, ->
        page.visit store.slug, product._id.toString(), ->
          page.setFieldsAs shipping: applies: true, ->
            page.clickUpdateProduct done
    it 'is at the product manage page', (done) ->
      page.currentUrl (url) ->
        url.should.equal "http://localhost:8000/admin/manageProduct/#{product.storeSlug}/#{product._id}"
        done()
    it 'shows error messages', (done) ->
      page.errorMessagesIn '#editProduct', (errorMsgs) ->
        errorMsgs.shippingHeight.should.equal 'A altura de postagem é obrigatória.'
        errorMsgs.shippingWidth.should.equal 'A largura de postagem é obrigatória.'
        errorMsgs.shippingDepth.should.equal 'A profundidade de postagem é obrigatória.'
        errorMsgs.shippingWeight.should.equal 'O peso de postagem é obrigatório.'
        done()

  describe 'editing product', ->
    otherProduct = null
    before (done) ->
      otherProduct = generator.product.b()
      page.loginFor userSeller._id, ->
        page.visit store.slug, product._id.toString(), ->
          page.setFieldsAs otherProduct, ->
            page.clickUpdateProduct done
    it 'is at the store manage page', (done) ->
      page.currentUrl (url) ->
        url.should.equal "http://localhost:8000/admin/store/#{product.storeSlug}"
        done()
    it 'updated the product', (done) ->
      Product.findById product._id, (err, productOnDb) ->
        return done err if err
        productOnDb.name.should.equal otherProduct.name
        productOnDb.price.should.equal otherProduct.price
        productOnDb.tags.should.be.like otherProduct.tags
        productOnDb.description.should.equal otherProduct.description
        productOnDb.dimensions.height.should.equal otherProduct.dimensions.height
        productOnDb.dimensions.width.should.equal otherProduct.dimensions.width
        productOnDb.dimensions.depth.should.equal otherProduct.dimensions.depth
        productOnDb.weight.should.equal otherProduct.weight
        productOnDb.shipping.applies.should.equal otherProduct.shipping.applies
        productOnDb.shipping.charge.should.equal otherProduct.shipping.charge
        productOnDb.shipping.dimensions.height.should.equal otherProduct.shipping.dimensions.height
        productOnDb.shipping.dimensions.width.should.equal otherProduct.shipping.dimensions.width
        productOnDb.shipping.dimensions.depth.should.equal otherProduct.shipping.dimensions.depth
        productOnDb.shipping.weight.should.equal otherProduct.shipping.weight
        productOnDb.hasInventory.should.equal otherProduct.hasInventory
        productOnDb.inventory.should.equal otherProduct.inventory
        done()

  describe 'adding category to a product', ->
    before (done) ->
      page.loginFor userSeller._id, ->
        page.visit store.slug, product._id.toString(), ->
          page.setCategories "Cat1, Cat2", ->
            page.clickUpdateProduct done
    it 'is at the store manage page', (done) ->
      page.currentUrl (url) ->
        url.should.equal "http://localhost:8000/admin/store/#{product.storeSlug}"
        done()
    it 'added category to the product', (done) ->
      Product.findById product._id, (err, productOnDb) ->
        return done err if err
        productOnDb.categories.length.should.equal 2
        productOnDb.categories.should.contain "Cat1"
        productOnDb.categories.should.contain "Cat2"
        done()
    it 'added category to the store', (done) ->
      Store.findBySlug product.storeSlug, (err, storeOnDb) ->
        return done err if err
        storeOnDb.categories.length.should.equal 2
        storeOnDb.categories.should.contain "Cat1"
        storeOnDb.categories.should.contain "Cat2"
        done()

  describe 'deleting product', ->
    otherProduct = null
    before (done) ->
      page.loginFor userSeller._id, ->
        page.visit store.slug, product2._id.toString(), ->
          page.clickDeleteProduct ->
            page.clickConfirmDeleteProduct ->
              page.waitForUrl "http://localhost:8000/admin/store/#{product2.storeSlug}", done
    it 'is at the store manage page', (done) ->
      page.currentUrl (url) ->
        url.should.equal "http://localhost:8000/admin/store/#{product2.storeSlug}"
        done()
    it 'deleted the product', (done) ->
      Product.findById product2._id, (err, productOnDb) ->
        return done err if err
        expect(productOnDb).to.be.null
        done()

  describe 'editing a product with upload', ->
    uploadedRegexMatch = /^https:\/\/s3\.amazonaws\.com\/dryrun\/store_1\/products\/\d+\.png$/
    uploadedThumbRegexMatch = /^https:\/\/s3\.amazonaws\.com\/dryrun\/store_1\/products\/\d+_thumb150x150\.png$/
    product3 = null
    before (done) ->
      AmazonFileUploader.filesUploaded.length = 0
      product3 = generator.product.e()
      product3.picture = null
      product3.save()
      page.loginFor userSeller._id, ->
        page.visit store.slug, product3._id.toString(), ->
          filePath = path.join __dirname, 'support', 'images', '700x700.png'
          page.setPictureFile filePath, ->
            page.clickUpdateProduct done
    it 'is at the store manage page', (done) ->
      page.currentUrl (url) ->
        url.should.equal "http://localhost:8000/admin/store/#{product3.storeSlug}"
        done()
    it 'updated the product to include the file', (done) ->
      Product.findById product3._id, (err, productOnDb) ->
        return done err if err
        productOnDb.picture.should.match uploadedRegexMatch
        done()
    it 'tried to upload the file', ->
      AmazonFileUploader.filesUploaded.length.should.equal 2
      AmazonFileUploader.filesUploaded[0].should.match uploadedRegexMatch
      AmazonFileUploader.filesUploaded[1].should.match uploadedThumbRegexMatch
    it 'did not update other characteristics of the product', (done) ->
      Product.findById product3._id, (err, productOnDb) ->
        return done err if err
        productOnDb.name.should.equal product3.name
        productOnDb.price.should.equal product3.price
        productOnDb.tags.should.be.like product3.tags
        productOnDb.description.should.equal product3.description
        productOnDb.dimensions.height.should.equal product3.dimensions.height
        productOnDb.dimensions.width.should.equal product3.dimensions.width
        productOnDb.dimensions.depth.should.equal product3.dimensions.depth
        productOnDb.weight.should.equal product3.weight
        productOnDb.shipping.applies.should.equal product3.shipping.applies
        productOnDb.shipping.charge.should.equal product3.shipping.charge
        productOnDb.shipping.dimensions.height.should.equal product3.shipping.dimensions.height
        productOnDb.shipping.dimensions.width.should.equal product3.shipping.dimensions.width
        productOnDb.shipping.dimensions.depth.should.equal product3.shipping.dimensions.depth
        productOnDb.shipping.weight.should.equal product3.shipping.weight
        productOnDb.hasInventory.should.equal product3.hasInventory
        productOnDb.inventory.should.equal product3.inventory
        done()
