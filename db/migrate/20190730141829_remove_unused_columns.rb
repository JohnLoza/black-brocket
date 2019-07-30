class RemoveUnusedColumns < ActiveRecord::Migration[5.1]
  def change
    drop_table :parcel_prices
    drop_table :parcels

    remove_column :clients, :bank_reference
    remove_column :clients, :lastname
    remove_column :clients, :mother_lastname
    remove_column :clients, :birthday

    remove_column :distributor_candidates, :lastname
    remove_column :distributor_candidates, :mother_lastname

    remove_column :fiscal_data, :lastname
    remove_column :fiscal_data, :mother_lastname

    remove_column :orders, :freight_worker_id
    remove_column :shipments, :freight_worker_id

    remove_column :permissions, :supervisor
    remove_column :permissions, :warehouse_chief

    remove_column :products, :shipping_cost

    remove_column :suggestions, :response

    remove_column :tip_recipes, :video_type

    remove_column :warehouses, :is_central

    remove_column :web_infos, :active
    remove_column :web_photos, :active
    remove_column :web_videos, :active

    Order.all.each do |order|
      if order.pay_pdf.present?
        order.pay_img = order.pay_pdf
        order.save
      end
    end

    rename_column :orders, :pay_img, :payment
    remove_column :orders, :pay_pdf

    Commission.all.each do |commission|
      if commission.payment_pdf.present?
        commission.payment_img = order.payment_pdf
        commission.save
      end
    end

    rename_column :commissions, :payment_img, :payment
    remove_column :commissions, :payment_pdf
  end
end
